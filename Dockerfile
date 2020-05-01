FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine-arm64v8 AS runtime
WORKDIR /app
COPY published/ ./
ENTRYPOINT ["dotnet", "api.dll"]