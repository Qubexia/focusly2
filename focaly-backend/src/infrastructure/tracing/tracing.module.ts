import { Module } from '@nestjs/common';

@Module({})
export class TracingModule {
  // OpenTelemetry bootstrap normally lives in a separate tracing.ts file loaded
  // before the Nest app. Wiring the SDK here keeps the module surface stable
  // for now; the real instrumentation registration happens in Phase 12 polish.
}
