from setuptools import find_packages, setup

setup(
    name="custom_transform_example",
    version="1.0",
    packages=find_packages(),
    # if you don't already have DataHub installed, add it under install_requires
    # install_requires=["acryl-datahub"],
    entry_points={
        "datahub.ingestion.transformer.plugins": [
            "custom_transform_example_alias = custom_transform_example:AddCustomOwnership",
        ],
    },
)