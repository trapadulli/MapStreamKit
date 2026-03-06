FROM mcr.microsoft.com/azure-databases/data-api-builder:latest

WORKDIR /App
COPY dab-config.json /App/dab-config.json
COPY schema.graphql /App/schema.graphql

CMD ["dab", "start", "--config", "/App/dab-config.json", "--host", "0.0.0.0", "--port", "5000"]
