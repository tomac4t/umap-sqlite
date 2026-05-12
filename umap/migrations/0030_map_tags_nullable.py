# Generated for SQLite compatibility - make tags nullable
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("umap", "0029_datalayer_parent"),
    ]

    operations = [
        migrations.AlterField(
            model_name="map",
            name="tags",
            field=models.JSONField(blank=True, default=list, null=True),
        ),
    ]
