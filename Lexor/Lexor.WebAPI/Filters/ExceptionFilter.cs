using FluentValidation;
using Lexor.Model.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using System.Net;

namespace Lexor.WebAPI.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        private readonly ILogger<ExceptionFilter> _logger;
        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            _logger = logger;
        }

        public override void OnException(ExceptionContext context)
        {
            switch (context.Exception)
            {
                case ValidationException fvEx:
                    SetResult(context, HttpStatusCode.BadRequest,
                        fvEx.Errors.FirstOrDefault()?.ErrorMessage ?? fvEx.Message);
                    break;

                case NotFoundException nfEx:
                    SetResult(context, HttpStatusCode.NotFound, nfEx.Message);
                    break;

                case BusinessException bEx:
                    SetResult(context, HttpStatusCode.BadRequest, bEx.Message);
                    break;

                case DbUpdateException dbEx when IsForeignKeyViolation(dbEx):
                    SetResult(context, HttpStatusCode.Conflict,
                        "Zapis se ne može obrisati jer se koristi u drugim podacima.");
                    break;

                default:
                    _logger.LogError(context.Exception, "Neočekivana greška.");
                    SetResult(context, HttpStatusCode.InternalServerError, "Greška na serveru.");
                    break;
            }
        }

        private static void SetResult(ExceptionContext context, HttpStatusCode status, string message)
        {
            context.HttpContext.Response.StatusCode = (int)status;
            context.Result = new JsonResult(new { message });
        }

        private static bool IsForeignKeyViolation(DbUpdateException ex)
        {
            for (Exception? e = ex; e != null; e = e.InnerException)
            {
                var msg = e.Message ?? string.Empty;
                if (msg.Contains("REFERENCE constraint", StringComparison.OrdinalIgnoreCase)
                    || msg.Contains("conflicted with the REFERENCE", StringComparison.OrdinalIgnoreCase)
                    || msg.Contains("FK_", StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }
            return false;
        }
    }
}