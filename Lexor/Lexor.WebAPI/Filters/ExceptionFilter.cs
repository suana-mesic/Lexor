using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using System.Net;

namespace Lexor.WebAPI.Filters
{
    public class ExceptionFilter:ExceptionFilterAttribute
    {
        private readonly ILogger<ExceptionFilter> _logger;
        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            _logger = logger;
        }
        public override void OnException(ExceptionContext context)
        {
            if(context.Exception is ValidationException fvEx)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                var message = fvEx.Errors.FirstOrDefault()?.ErrorMessage ?? fvEx.Message;
                context.Result = new JsonResult(new { message });
            }
            else if (context.Exception is KeyNotFoundException knfEx)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.NotFound;
                context.Result = new JsonResult(new { message = knfEx.Message });
            }
            else if (context.Exception is DbUpdateException dbEx && IsForeignKeyViolation(dbEx))
            {
                // Zapis se koristi u drugim tabelama (FK ograničenje) — jasna poruka umjesto 500.
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Conflict;
                context.Result = new JsonResult(new
                {
                    message = "Zapis se ne može obrisati jer se koristi u drugim podacima."
                });
            }
            else if (context.Exception is InvalidOperationException ioEx)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                context.Result = new JsonResult(new { message = ioEx.Message });
            }
            else
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                _logger.LogError(context.Exception, "Neočekivana greška.");
                context.Result = new JsonResult(new { message = "Greška na serveru." });
            }
        }

        private static bool IsForeignKeyViolation(DbUpdateException ex)
        {
            // SQL Server FK constraint = error 547; provjeravamo preko poruke da izbjegnemo
            // tvrdu zavisnost na Microsoft.Data.SqlClient u ovom sloju.
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
