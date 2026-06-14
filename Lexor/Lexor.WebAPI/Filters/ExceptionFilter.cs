using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
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
    }
}
