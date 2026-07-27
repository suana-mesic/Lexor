using DotNetEnv;
using EasyNetQ;
using Lexor.Services;
using Lexor.Services.Database;
using Lexor.Subscriber;
using Microsoft.EntityFrameworkCore;
using SmartComponents.LocalEmbeddings;

Env.TraversePath().Load();

var builder=Host.CreateApplicationBuilder();

builder.Services.AddDbContext<LexorDbContext>(options => options.UseSqlServer(builder.Configuration["ConnectionStrings:DefaultConnection"]));

builder.Services.AddSingleton<IBus>(_ =>
    RabbitHutch.CreateBus(builder.Configuration["RabbitMQ:ConnectionString"]));

builder.Services.AddHostedService<LeaveNotificationConsumer>();
builder.Services.AddHostedService<LeaveCompletionWorker>();
builder.Services.AddSingleton(new LocalEmbedder());
builder.Services.AddHostedService<LegalDocumentIndexConsumer>();
builder.Services.AddScoped<ILegalDocumentIndexer, LegalDocumentIndexer>();

var host = builder.Build();
host.Run(); 