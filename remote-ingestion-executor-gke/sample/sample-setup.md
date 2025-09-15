# Sample Data Source and Transformer Setup Guide

This guide walks you through setting up the sample PostgreSQL data source, custom transformers, and testing the complete DataHub ingestion pipeline with the remote executor.

## 📋 Overview

The sample setup includes:
- **PostgreSQL Database**: Sample data source with test tables
- **Custom Transformer**: Adds ownership metadata to ingested datasets
- **Ingestion Recipe**: Configuration for DataHub ingestion
- **Remote Executor**: Processes ingestion with custom transformations

## 🐘 PostgreSQL Data Source Setup

### 1. Deploy Sample PostgreSQL

The repository includes Kubernetes manifests for a sample PostgreSQL instance:

```bash
# Deploy PostgreSQL to your GKE cluster
kubectl apply -f sample/source/postgres-config.yaml
kubectl apply -f sample/source/postgres-deployment.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s
```

### 2. Verify PostgreSQL Deployment

```bash
# Check if PostgreSQL is running
kubectl get pods -l app=postgres

# Check service
kubectl get svc postgres-service

# Test connection (optional)
kubectl exec -it deployment/postgres -- psql -U testuser -d testdb -c "SELECT version();"
```

### 3. Sample Database Schema

The PostgreSQL instance comes pre-configured with sample data:

```sql
-- Sample tables that will be ingested
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_name VARCHAR(100),
    amount DECIMAL(10,2),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data
INSERT INTO users (username, email) VALUES 
    ('alice', 'alice@example.com'),
    ('bob', 'bob@example.com');

INSERT INTO orders (user_id, product_name, amount) VALUES 
    (1, 'Widget A', 29.99),
    (2, 'Widget B', 39.99);
```

## 🔧 Custom Transformer Configuration

### 1. Understanding the Sample Transformer

The sample transformer (`sample/transformers/custom_transform_example.py`) demonstrates:

```python
class AddCustomOwnership(BaseTransformer, SingleAspectTransformer):
    """Transformer that adds owners to datasets according to a callback function."""
    
    def transform_aspect(self, entity_urn: str, aspect_name: str, aspect: Optional[OwnershipClass]) -> Optional[OwnershipClass]:
        # Adds predefined owners to all datasets
        owners_to_add = self.owners  # Loaded from owners.json
        # ... transformation logic
```

### 2. Customizing Ownership

Edit `sample/transformers/owners.json` to customize ownership:

```json
[
  "urn:li:corpuser:your-username",
  "urn:li:corpuser:data-engineer",
  "urn:li:corpGroup:data-team"
]
```

### 3. Transformer Entry Points

The `setup.py` file registers the transformer:

```python
entry_points={
    "datahub.ingestion.transformer.plugins": [
        "custom_transform_example_alias = custom_transform_example:AddCustomOwnership",
    ],
}
```

## 📝 Ingestion Recipe Configuration

### 1. Sample Recipe Structure

The sample recipe (`sample/source/postgres-recipe.yaml`) configures:

```yaml
source:
  type: postgres
  config:
    host_port: postgres-service:5432
    database: testdb
    username: testuser
    password: testpass
    
transformers:
  - type: "custom_transform_example_alias"
    config:
      owners_json: "/opt/datahub/transformers/owners.json"

sink:
  type: "datahub-rest"
  config:
    server: "${DATAHUB_GMS_URL}"
    token: "${DATAHUB_GMS_TOKEN}"
```

### 2. Recipe Customization

To customize the ingestion:

1. **Database Configuration**: Update connection details in the `source.config` section
2. **Table Filtering**: Add `table_pattern` to include/exclude specific tables
3. **Schema Mapping**: Configure schema and database naming
4. **Transformer Parameters**: Modify transformer configuration

Example with table filtering:

```yaml
source:
  type: postgres
  config:
    host_port: postgres-service:5432
    database: testdb
    username: testuser
    password: testpass
    table_pattern:
      allow:
        - "public.users"
        - "public.orders"
      deny:
        - "public.temp_.*"
```

## 🚀 Running the Complete Pipeline

### 1. Deploy the Remote Executor

Ensure your Terraform deployment is complete:

```bash
# Check executor status
kubectl get pods -n datahub-remote-executor

# Verify custom transformers are loaded
kubectl logs -n datahub-remote-executor -l app.kubernetes.io/name=datahub-executor-worker --tail=50 | grep "transformer"
```

### 2. Create Ingestion Source in DataHub

1. **Navigate to DataHub UI** → Ingestion → Sources
2. **Create New Source**:
   - Source Type: PostgreSQL
   - Executor: Select your remote executor pool (`gke-executor-pool`)
   - Recipe: Copy content from `sample/source/postgres-recipe.yaml`

3. **Configure Connection**:
   - Host: `postgres-service.default.svc.cluster.local:5432` (if PostgreSQL is in default namespace)
   - Database: `testdb`
   - Username: `testuser`
   - Password: `testpass`

### 3. Test the Ingestion

1. **Run Ingestion**: Click "Execute" in DataHub UI
2. **Monitor Progress**: Watch the ingestion logs in DataHub
3. **Check Executor Logs**:
   ```bash
   kubectl logs -n datahub-remote-executor -l app.kubernetes.io/name=datahub-executor-worker -f
   ```

### 4. Verify Results

After successful ingestion:

1. **Check Datasets**: Navigate to DataHub UI → Browse → Datasets
2. **Verify Ownership**: Look for datasets with the custom ownership applied
3. **Inspect Metadata**: Check that schema and lineage information is captured

## 🔍 Troubleshooting

### Common Issues

#### 1. Connection Issues
```bash
# Check if PostgreSQL is accessible from executor
kubectl exec -it deployment/datahub-executor-datahub-executor-worker -n datahub-remote-executor -- nslookup postgres-service.default.svc.cluster.local
```

#### 2. Transformer Not Loading
```bash
# Check if transformer files are mounted
kubectl exec -it deployment/datahub-executor-datahub-executor-worker -n datahub-remote-executor -- ls -la /opt/datahub/transformers/

# Verify transformer installation
kubectl logs -n datahub-remote-executor -l app.kubernetes.io/name=datahub-executor-worker | grep "install"
```

#### 3. Authentication Issues
```bash
# Check if DataHub secrets are properly mounted
kubectl get secrets -n datahub-remote-executor
kubectl describe secret datahub-access-token -n datahub-remote-executor
```

### Debug Commands

```bash
# Test PostgreSQL connection
kubectl exec -it deployment/postgres -- psql -U testuser -d testdb -c "\dt"

# Check executor environment
kubectl exec -it deployment/datahub-executor-datahub-executor-worker -n datahub-remote-executor -- env | grep DATAHUB

# Verify ConfigMap content
kubectl describe configmap custom-transformers -n datahub-remote-executor

# Check Python path and installed packages
kubectl exec -it deployment/datahub-executor-datahub-executor-worker -n datahub-remote-executor -- python -c "import sys; print(sys.path)"
```

## 🎯 Testing Custom Transformations

### 1. Validate Transformer Logic

Test your transformer locally before deployment:

```python
# test_transformer.py
from custom_transform_example import AddCustomOwnership
from datahub.configuration.common import ConfigModel

# Test configuration
config = {"owners_json": "owners.json"}
transformer = AddCustomOwnership.create(config, None)

# Test transformation
result = transformer.transform_aspect("test_urn", "ownership", None)
print(f"Added owners: {[owner.owner for owner in result.owners]}")
```

### 2. Monitor Transformation Results

```bash
# Check transformation logs
kubectl logs -n datahub-remote-executor -l app.kubernetes.io/name=datahub-executor-worker | grep -i "transform"

# Verify ownership in DataHub
# Navigate to a dataset in DataHub UI and check the Ownership tab
```

## 🔄 Updating Transformers

### 1. Modify Transformer Code

1. Edit files in `sample/transformers/`
2. Update version in `setup.py` if needed
3. Test changes locally

### 2. Redeploy

```bash
# Apply Terraform changes
terraform apply

# Check if new ConfigMap is created
kubectl get configmap custom-transformers -n datahub-remote-executor -o yaml

# Restart executor pods to pick up changes
kubectl rollout restart deployment/datahub-executor-datahub-executor-worker -n datahub-remote-executor
```

## 📊 Advanced Configuration

### 1. Multiple Data Sources

To add more data sources, create additional recipe files and configure them in DataHub:

```bash
# Create new recipe
cp sample/source/postgres-recipe.yaml sample/source/mysql-recipe.yaml
# Edit mysql-recipe.yaml with MySQL-specific configuration
```

### 2. Complex Transformers

For more complex transformations:

```python
class AdvancedTransformer(BaseTransformer):
    def transform(self, record):
        # Apply business logic
        # Add tags based on table names
        # Set domains based on schema
        # Apply data classification
        return record
```

### 3. Environment-Specific Configuration

Use different transformer configurations per environment:

```bash
# Development
custom_transformers_path = "sample/transformers/dev"

# Production  
custom_transformers_path = "sample/transformers/prod"
```

## 🎓 Next Steps

1. **Explore DataHub Features**: Lineage, Data Quality, Glossary
2. **Add More Transformers**: Create transformers for tagging, domains, etc.
3. **Scale the Setup**: Increase replica count for higher throughput
4. **Monitor Performance**: Set up monitoring and alerting
5. **Implement CI/CD**: Automate transformer deployment

## 📚 Additional Resources

- [DataHub Transformers Documentation](https://datahubproject.io/docs/metadata-ingestion/docs/transformer/intro)
- [PostgreSQL Source Configuration](https://datahubproject.io/docs/generated/ingestion/sources/postgres)
- [Remote Executor Setup](https://datahubproject.io/docs/managed-datahub/operator-guide/setting-up-remote-ingestion-executor)
- [DataHub API Guide](https://datahubproject.io/docs/api/datahub-apis)
