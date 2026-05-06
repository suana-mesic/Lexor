using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi.Models;

namespace Lexor.WebAPI
{
    public class BearerSecuritySchemeTransformer : IOpenApiDocumentTransformer
    {
        public Task TransformAsync(
            OpenApiDocument document,
            OpenApiDocumentTransformerContext context,
            CancellationToken cancellationToken)
        {
            var securityScheme = new OpenApiSecurityScheme
            {
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT",
                In = ParameterLocation.Header,
                Description = "Enter your JWT access token"
            };

            document.Components ??= new OpenApiComponents();
            document.Components.SecuritySchemes = new Dictionary<string, OpenApiSecurityScheme>
            {
                ["Bearer"] = securityScheme
            };

            var securityRequirement = new OpenApiSecurityRequirement
            {
                [new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference
                    {
                        Type = ReferenceType.SecurityScheme,
                        Id = "Bearer"
                    }
                }] = Array.Empty<string>()
            };

            foreach (var apiDescription in context.DescriptionGroups.SelectMany(g => g.Items))
            {
                var hasAllowAnonymous = apiDescription.ActionDescriptor.EndpointMetadata
                    .OfType<AllowAnonymousAttribute>()
                    .Any();

                if (hasAllowAnonymous)
                    continue;

                var pathKey = "/" + apiDescription.RelativePath;
                if (!document.Paths.TryGetValue(pathKey, out var pathItem))
                    continue;

                if (!Enum.TryParse<OperationType>(apiDescription.HttpMethod, true, out var opType))
                    continue;

                if (pathItem.Operations.TryGetValue(opType, out var operation))
                {
                    operation.Security.Add(securityRequirement);
                }
            }

            return Task.CompletedTask;
        }
    }
}