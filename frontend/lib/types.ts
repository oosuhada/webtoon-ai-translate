export type ID = number | string;

export interface User {
  id: number;
  email: string;
  name: string;
  isAdmin: boolean;
}

export interface ApiUser {
  id: number;
  email: string;
  name: string;
  is_active: boolean;
  is_admin: boolean;
  created_at: string;
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  token_type: "bearer";
  user: ApiUser;
}

export interface JobStatus {
  status: "pending" | "processing" | "done" | "failed";
  progress: number;
  error?: string;
}

export interface Character {
  id: ID;
  name: string;
  description: string;
  speechStyle: string;
  speechExamples: string[];
}

export interface Episode {
  id: ID;
  number: number;
  title: string;
  synopsis: string;
  status: string;
  characterSituations: Record<string, string>;
}

export interface Bubble {
  id: ID;
  pageId: ID;
  labelIndex: number;
  x1: number;
  y1: number;
  x2: number;
  y2: number;
  originalText: string;
  speaker?: string;
  speakerIsConfirmed: boolean;
  bubbleType: "dialogue" | "sfx" | "narration";
  candidates: TranslationCandidate[];
}

export interface TranslationCandidate {
  id: ID;
  rank: number;
  text: string;
  rationale: string;
  isSelected: boolean;
  customText?: string;
}
