"use client";

import { useRouter } from "next/navigation";

import { Button } from "@/components/ui/button";

export default function DashboardPage() {
  const router = useRouter();

  function handleLogout() {
    window.localStorage.removeItem("access_token");
    window.localStorage.removeItem("refresh_token");
    document.cookie = "access_token=; path=/; max-age=0; SameSite=Lax";
    router.push("/login");
  }

  return (
    <main className="min-h-screen bg-background">
      <header className="border-b bg-card">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4">
          <div>
            <p className="text-sm font-medium text-primary">AI Losy</p>
            <h1 className="text-lg font-semibold">프로젝트 대시보드</h1>
          </div>
          <Button variant="outline" onClick={handleLogout}>
            로그아웃
          </Button>
        </div>
      </header>

      <section className="mx-auto max-w-6xl px-4 py-10">
        <div className="rounded-lg border bg-card p-6 shadow-sm">
          <h2 className="text-xl font-semibold">번역 프로젝트</h2>
          <p className="mt-2 text-sm text-muted-foreground">
            다음 단계에서 작품 컨텍스트와 회차 업로드 흐름이 이 화면에 연결됩니다.
          </p>
        </div>
      </section>
    </main>
  );
}
