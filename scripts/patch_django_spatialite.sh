#!/bin/bash
# Django SpatiaLite patches for uMap SQLite migration
# These patches fix compatibility issues between Django 5.2 and SpatiaLite 5.0.1
# Run this after `pip install -e .` in the uMap virtualenv.

DJANGO_DIR=$(python -c "import django; print(django.__path__[0])" 2>/dev/null)
if [ -z "$DJANGO_DIR" ]; then
    echo "Error: Django not found. Activate the venv first."
    exit 1
fi

echo "Patching Django for SpatiaLite compatibility..."

# Patch 1: InitSpatialMetaDataFull(0) - disable RTT triggers during metadata init.
# Mode 0 still creates triggers in SpatiaLite 5.0.1, but this is a safety measure.
BASE_PY="$DJANGO_DIR/contrib/gis/db/backends/spatialite/base.py"
if grep -q 'InitSpatialMetaDataFull(0)' "$BASE_PY"; then
    echo "  [OK] base.py already patched (InitSpatialMetaDataFull mode 0)"
else
    sed -i 's/InitSpatialMetaDataFull(1)/InitSpatialMetaDataFull(0)/' "$BASE_PY"
    echo "  [OK] base.py patched: InitSpatialMetaDataFull(1) -> (0)"
fi

# Patch 2: Disable/enable spatialite triggers around ALTER TABLE RENAME.
# This prevents "rowid" errors during Django's _remake_table operations.
SCHEMA_PY="$DJANGO_DIR/contrib/gis/db/backends/spatialite/schema.py"
if grep -q 'DisableSpatialiteTriggers' "$SCHEMA_PY"; then
    echo "  [OK] schema.py already patched (DisableSpatialiteTriggers)"
else
    python3 -c "
import re
with open('$SCHEMA_PY', 'r') as f:
    content = f.read()
old = '''        # Alter table
        super().alter_db_table(model, old_db_table, new_db_table)'''
new = '''        # Disable spatialite triggers to avoid rowid issues during table rename
        try:
            self.execute(\"SELECT DisableSpatialiteTriggers()\")
        except DatabaseError:
            pass
        # Alter table
        super().alter_db_table(model, old_db_table, new_db_table)
        # Re-enable spatialite triggers
        try:
            self.execute(\"SELECT EnableSpatialiteTriggers()\")
        except DatabaseError:
            pass'''
content = content.replace(old, new)
with open('$SCHEMA_PY', 'w') as f:
    f.write(content)
print('  [OK] schema.py patched: trigger disable/enable around alter_db_table')
"
fi

echo "Django patches applied."
