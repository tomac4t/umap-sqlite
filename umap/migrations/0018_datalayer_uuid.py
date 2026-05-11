# Modified for SQLite compatibility
import uuid

from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("umap", "0017_migrate_to_openstreetmap_oauth2"),
    ]

    operations = [
        # 1. Rename id -> old_id (SQLite ALTER TABLE RENAME COLUMN, preserves PK)
        migrations.RenameField(
            model_name="datalayer", old_name="id", new_name="old_id"
        ),
        # 2. Change old_id from AutoField(PK) to plain IntegerField (non-PK, non-auto_created)
        #    This triggers _remake_table but preserves old_id since it's no longer auto_created.
        migrations.AlterField(
            model_name="datalayer",
            name="old_id",
            field=models.IntegerField(blank=True, null=True),
        ),
        # 3. Add uuid as the new PK (triggers _remake_table)
        migrations.AddField(
            model_name="datalayer",
            name="uuid",
            field=models.UUIDField(
                default=uuid.uuid4,
                editable=False,
                unique=True,
                primary_key=True,
                serialize=False,
            ),
        ),
    ]
