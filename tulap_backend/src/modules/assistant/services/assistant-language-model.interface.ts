export interface AssistantSynthesisRequest {
  query: string;
  contextDescription?: string;
  minimalRecords: Array<{
    type: string;
    title: string;
    date?: string;
    location?: string;
    status?: string;
    amount?: string | number;
    notes?: string;
  }>;
}

export abstract class AssistantLanguageModel {
  abstract isAvailable(): boolean;
  abstract synthesizeAnswer(request: AssistantSynthesisRequest): Promise<string>;
}
