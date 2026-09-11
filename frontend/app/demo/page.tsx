"use client";

import { useMemo, useState } from "react";
import Link from "next/link";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";

type Memory = {
  source: string;
  finalText: string;
  character: string;
  note: string;
};

const sample = {
  project: "달빛의 기사단",
  character: "하루",
  style: "겁을 숨기며 센 척하는 짧은 반말",
  firstSource: "黒騎士なんて、怖くない！",
  secondSource: "また黒騎士か。今度は逃げない。",
  firstCandidates: [
    "흑기사 따위, 안 무서워!",
    "흑기사라고? 하나도 안 무섭거든!",
    "그깟 흑기사, 별거 아니야!",
  ],
};

function buildSecondCandidates(memory: Memory | null) {
  const learnedTone = memory
    ? "앞서 확정한 짧은 반말과 ‘흑기사’ 용어를 유지"
    : "프로젝트 기본 말투만 사용";

  return {
    learnedTone,
    candidates: memory
      ? [
          "또 흑기사네. 이번엔 안 도망쳐.",
          "또 흑기사야? 이번엔 절대 안 피해.",
          "또 그 흑기사인가. 이번엔 도망치지 않아.",
        ]
      : [
          "또 검은 기사인가. 이번에는 도망가지 않겠다.",
          "다시 블랙 나이트군. 이번에는 피하지 않겠다.",
          "또 흑기사인가. 이번에는 도망치지 않겠다.",
        ],
  };
}

export default function TranslationMemoryDemoPage() {
  const [selected, setSelected] = useState(0);
  const [editedText, setEditedText] = useState(sample.firstCandidates[0]);
  const [memory, setMemory] = useState<Memory | null>(null);
  const [secondSelected, setSecondSelected] = useState(0);

  const second = useMemo(() => buildSecondCandidates(memory), [memory]);

  function chooseCandidate(index: number) {
    setSelected(index);
    setEditedText(sample.firstCandidates[index]);
  }

  function saveMemory() {
    setMemory({
      source: sample.firstSource,
      finalText: editedText.trim() || sample.firstCandidates[selected],
      character: sample.character,
      note: `${sample.character}의 짧은 반말 + 고유명사 ‘흑기사’를 다음 장면에 재사용`,
    });
    setSecondSelected(0);
  }

  function resetDemo() {
    setSelected(0);
    setEditedText(sample.firstCandidates[0]);
    setMemory(null);
    setSecondSelected(0);
  }

  return (
    <main className="min-h-screen bg-muted/30 py-10">
      <div className="mx-auto flex max-w-6xl flex-col gap-6 px-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-medium text-primary">AI Losy · reviewer memory demo</p>
            <h1 className="mt-1 text-3xl font-semibold tracking-tight">
              사람의 수정이 다음 장면의 번역 후보로 이어지는가
            </h1>
            <p className="mt-2 max-w-3xl text-sm leading-6 text-muted-foreground">
              정부지원 심사용 deterministic vertical slice입니다. 실제 OCR/LLM 호출 대신 저작권 없는
              자체 샘플과 고정 후보를 사용해 human correction → project memory → next-page reuse라는
              제품 가설만 검증합니다.
            </p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={resetDemo}>초기화</Button>
            <Button asChild variant="secondary"><Link href="/dashboard">대시보드</Link></Button>
          </div>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>{sample.project}</CardTitle>
            <CardDescription>
              캐릭터: {sample.character} · 말투 가이드: {sample.style}
            </CardDescription>
          </CardHeader>
        </Card>

        <div className="grid gap-6 lg:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Scene 1 · 후보 선택과 human edit</CardTitle>
              <CardDescription>OCR 결과라고 가정한 원문을 사람이 검토하고 최종 번역을 확정합니다.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-5">
              <div className="rounded-lg border bg-muted/40 p-4">
                <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Source</p>
                <p className="mt-2 text-lg font-medium">{sample.firstSource}</p>
              </div>

              <div className="space-y-2">
                <p className="text-sm font-medium">번역 후보</p>
                {sample.firstCandidates.map((candidate, index) => (
                  <button
                    key={candidate}
                    type="button"
                    onClick={() => chooseCandidate(index)}
                    className={`w-full rounded-lg border p-3 text-left text-sm transition ${
                      selected === index ? "border-foreground bg-foreground text-background" : "bg-background hover:bg-muted"
                    }`}
                  >
                    <span className="mr-2 font-semibold">{index + 1}</span>{candidate}
                  </button>
                ))}
              </div>

              <div className="space-y-2">
                <label htmlFor="human-final" className="text-sm font-medium">번역가 최종 문장</label>
                <Input
                  id="human-final"
                  value={editedText}
                  onChange={(event) => setEditedText(event.target.value)}
                />
                <p className="text-xs text-muted-foreground">
                  후보를 그대로 채택하거나 직접 수정합니다. 이 최종값만 memory에 들어갑니다.
                </p>
              </div>
            </CardContent>
            <CardFooter className="justify-between gap-3">
              <span className="text-xs text-muted-foreground">AI candidate는 기록하되 정답으로 승격하지 않음</span>
              <Button onClick={saveMemory}>검수 확정 → Memory 저장</Button>
            </CardFooter>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Scene 2 · correction memory 재사용</CardTitle>
              <CardDescription>
                첫 장면의 human-approved correction이 다음 장면의 용어와 말투 컨텍스트로 반영됩니다.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-5">
              <div className="rounded-lg border bg-muted/40 p-4">
                <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Source</p>
                <p className="mt-2 text-lg font-medium">{sample.secondSource}</p>
              </div>

              <div className={`rounded-lg border p-4 ${memory ? "bg-emerald-50 text-emerald-950" : "bg-amber-50 text-amber-950"}`}>
                <p className="text-xs font-semibold uppercase tracking-wide">
                  {memory ? "Memory applied" : "Memory not learned yet"}
                </p>
                <p className="mt-2 text-sm">
                  {memory ? memory.note : "Scene 1을 확정하면 translator correction이 다음 후보 생성 컨텍스트에 들어갑니다."}
                </p>
                {memory ? (
                  <p className="mt-2 text-xs">확정 예시: {memory.source} → {memory.finalText}</p>
                ) : null}
              </div>

              <div className="space-y-2">
                <div className="flex items-center justify-between gap-3">
                  <p className="text-sm font-medium">다음 장면 후보</p>
                  <span className="text-xs text-muted-foreground">{second.learnedTone}</span>
                </div>
                {second.candidates.map((candidate, index) => (
                  <button
                    key={candidate}
                    type="button"
                    onClick={() => setSecondSelected(index)}
                    className={`w-full rounded-lg border p-3 text-left text-sm transition ${
                      secondSelected === index ? "border-primary bg-primary text-primary-foreground" : "bg-background hover:bg-muted"
                    }`}
                  >
                    <span className="mr-2 font-semibold">{index + 1}</span>{candidate}
                  </button>
                ))}
              </div>

              <div className="rounded-lg border border-dashed p-4 text-sm">
                <p className="font-medium">현재 vertical slice가 증명하는 것</p>
                <ul className="mt-2 list-disc space-y-1 pl-5 text-muted-foreground">
                  <li>AI 초안과 human final을 분리한다.</li>
                  <li>사람이 확정한 correction만 project memory로 축적한다.</li>
                  <li>누적 memory가 다음 회차/장면의 후보 생성 컨텍스트로 재사용된다.</li>
                </ul>
              </div>
            </CardContent>
          </Card>
        </div>

        <p className="text-xs leading-5 text-muted-foreground">
          Demo boundary: OCR, 실제 LLM 번역, image inpainting/typesetting은 아직 연결하지 않았습니다. 이 페이지는
          제품의 핵심 learning loop를 검증하기 위한 deterministic prototype입니다.
        </p>
      </div>
    </main>
  );
}
