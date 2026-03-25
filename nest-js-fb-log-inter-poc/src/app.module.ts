
import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { AppController } from './app.controller';
import { AppService } from './app.service';

// FluentBit address - defaults to localhost for local dev,
// use FLUENTBIT_HOST env var for Kubernetes (e.g., fluent-bit.monitoring.svc.cluster.local)
const fluentbitHost = process.env.FLUENTBIT_HOST || '127.0.0.1';
const fluentbitPort = parseInt(process.env.FLUENTBIT_PORT || '9000', 10);

const transport = {
  targets: [
    {
      target: 'pino-socket',
      options: {
        mode: 'tcp',
        address: fluentbitHost,
        port: fluentbitPort,
      },
    },
    {
      target: 'pino-pretty',
      level: 'debug',
      options: {
        colorize: true,
        singleLine: true,
        translateTime: 'SYS:standard'
      },
    }
  ]
}

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        transport: transport,
        level: 'info',
        serializers: {
          req: (req) => ({
            id: req.id,
            method: req.method,
            url: req.url,
          }),
          res: (res) => ({
            statusCode: res.statusCode,
          }),
        },
      },
    })
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }