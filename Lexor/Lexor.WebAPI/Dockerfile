# ---- Build stage: uses the full .NET SDK to compile and publish ----
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy only the .csproj files first so "restore" can be cached separately
COPY Lexor.WebAPI/Lexor.WebAPI.csproj Lexor.WebAPI/
COPY Lexor.Services/Lexor.Services.csproj Lexor.Services/
COPY Lexor.Model/Lexor.Model.csproj Lexor.Model/
RUN dotnet restore Lexor.WebAPI/Lexor.WebAPI.csproj

# Copy the rest of the source and publish a Release build
COPY . .
RUN dotnet publish Lexor.WebAPI/Lexor.WebAPI.csproj -c Release -o /app/publish

# ---- Runtime stage: small image that only runs the published app ----
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "Lexor.WebAPI.dll"]