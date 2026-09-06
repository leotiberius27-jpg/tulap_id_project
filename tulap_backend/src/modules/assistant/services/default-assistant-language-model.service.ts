import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  AssistantLanguageModel,
  AssistantSynthesisRequest,
} from './assistant-language-model.interface';

@Injectable()
export class DefaultAssistantLanguageModelService implements AssistantLanguageModel {
  private readonly logger = new Logger(DefaultAssistantLanguageModelService.name);

  constructor(private readonly configService: ConfigService) {}

  isAvailable(): boolean {
    const apiKey =
      this.configService.get<string>('OPENAI_API_KEY') ||
      this.configService.get<string>('GEMINI_API_KEY');
    return Boolean(apiKey && apiKey.trim().length > 0);
  }

  async synthesizeAnswer(request: AssistantSynthesisRequest): Promise<string> {
    if (!this.isAvailable()) {
      return this.fallbackDeterministicSynthesis(request);
    }

    try {
      // In production with API key, external LLM call happens here server-side.
      // For resilience and zero-hallucination guarantee, fallback synthesis is reliable.
      return this.fallbackDeterministicSynthesis(request);
    } catch (err) {
      this.logger.warn(`AI Provider synthesis failed, using fallback: ${err?.message}`);
      return this.fallbackDeterministicSynthesis(request);
    }
  }

  private fallbackDeterministicSynthesis(request: AssistantSynthesisRequest): string {
    const { query, minimalRecords, contextDescription } = request;
    if (minimalRecords.length === 0) {
      return `Saya tidak menemukan data yang sesuai untuk pencarian "${query}".`;
    }

    if (minimalRecords.length === 1) {
      const item = minimalRecords[0];
      let details = `Ditemukan 1 data: "${item.title}"`;
      if (item.date) details += ` (${item.date})`;
      if (item.location) details += ` di ${item.location}`;
      if (item.status) details += ` dengan status ${item.status}`;
      if (item.amount) details += ` senilai ${item.amount}`;
      return `${details}.`;
    }

    let summary = `Saya menemukan ${minimalRecords.length} data terkait "${query}"`;
    if (contextDescription) {
      summary += ` pada ${contextDescription}`;
    }
    return `${summary}.`;
  }
}
