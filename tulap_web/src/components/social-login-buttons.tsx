'use client';

import { useEffect, useRef, useState } from 'react';
import Script from 'next/script';
import { useRouter } from 'next/navigation';
import { AlertCircle } from 'lucide-react';

const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? '';
const APPLE_CLIENT_ID = process.env.NEXT_PUBLIC_APPLE_CLIENT_ID ?? '';

// Minimal shape of what we read off the global SDK objects — avoids
// pulling in full @types packages just for two fields.
declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: {
            client_id: string;
            callback: (response: { credential: string }) => void;
          }) => void;
          renderButton: (parent: HTMLElement, options: Record<string, unknown>) => void;
        };
      };
    };
    AppleID?: {
      auth: {
        init: (config: {
          clientId: string;
          scope: string;
          redirectURI: string;
          usePopup: boolean;
        }) => void;
        signIn: () => Promise<{
          authorization: { id_token: string };
          user?: { name?: { firstName?: string; lastName?: string } };
        }>;
      };
    };
  }
}

function AppleLogoIcon() {
  return (
    <svg
      width="18"
      height="18"
      viewBox="0 0 384 512"
      fill="currentColor"
      aria-hidden="true"
    >
      <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z" />
    </svg>
  );
}

export function SocialLoginButtons({ onError }: { onError: (message: string) => void }) {
  const hasAnyProvider = Boolean(GOOGLE_CLIENT_ID) || Boolean(APPLE_CLIENT_ID);

  if (!hasAnyProvider) {
    // Neither provider configured — say so plainly instead of rendering
    // dead buttons. This is the honest state, not a placeholder.
    return (
      <div className="mt-6 flex items-center gap-2 rounded-button border border-border bg-background/60 p-3 text-[11px] text-text-secondary">
        <AlertCircle className="h-3.5 w-3.5 shrink-0" />
        <span>
          Masuk dengan Google/Apple belum dikonfigurasi. Tambahkan{' '}
          <code className="rounded bg-border/60 px-1 py-0.5">NEXT_PUBLIC_GOOGLE_CLIENT_ID</code>{' '}
          atau{' '}
          <code className="rounded bg-border/60 px-1 py-0.5">NEXT_PUBLIC_APPLE_CLIENT_ID</code>{' '}
          di <code className="rounded bg-border/60 px-1 py-0.5">.env.local</code> untuk
          mengaktifkan.
        </span>
      </div>
    );
  }

  return (
    <div className="mt-6 space-y-3">
      <div className="flex items-center gap-3">
        <div className="h-px flex-1 bg-border" />
        <span className="text-[11px] font-medium text-text-secondary">atau masuk dengan</span>
        <div className="h-px flex-1 bg-border" />
      </div>
      <div className="space-y-2.5">
        {GOOGLE_CLIENT_ID ? <GoogleButton onError={onError} /> : <DisabledButton label="Google" />}
        {APPLE_CLIENT_ID ? <AppleButton onError={onError} /> : <DisabledButton label="Apple" />}
      </div>
    </div>
  );
}

function DisabledButton({ label }: { label: string }) {
  return (
    <button
      type="button"
      disabled
      title={`Masuk dengan ${label} belum dikonfigurasi (Client ID kosong)`}
      className="flex w-full items-center justify-center gap-2 rounded-button border border-border bg-background py-2.5 text-small font-medium text-text-secondary/50 cursor-not-allowed"
    >
      Lanjutkan dengan {label}
    </button>
  );
}

function GoogleButton({ onError }: { onError: (message: string) => void }) {
  const router = useRouter();
  const wrapperRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLDivElement>(null);
  const [scriptReady, setScriptReady] = useState(false);

  useEffect(() => {
    if (!scriptReady || !window.google || !buttonRef.current || !wrapperRef.current) return;

    window.google.accounts.id.initialize({
      client_id: GOOGLE_CLIENT_ID,
      callback: async (response) => {
        try {
          const res = await fetch('/api/auth/google', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ idToken: response.credential }),
          });
          const data = await res.json();
          if (!res.ok) {
            onError(data.message ?? 'Masuk dengan Google gagal.');
            return;
          }
          router.push('/tasks');
          router.refresh();
        } catch {
          onError('Tidak dapat terhubung ke server.');
        }
      },
    });

    const width = Math.min(400, Math.round(wrapperRef.current.getBoundingClientRect().width));

    window.google.accounts.id.renderButton(buttonRef.current, {
      theme: 'outline',
      size: 'large',
      shape: 'rectangular',
      logo_alignment: 'left',
      width,
      text: 'continue_with',
    });
  }, [scriptReady, router, onError]);

  return (
    <>
      <Script
        src="https://accounts.google.com/gsi/client?hl=id"
        strategy="afterInteractive"
        onReady={() => setScriptReady(true)}
      />
      <div ref={wrapperRef} className="flex justify-center">
        <div ref={buttonRef} />
      </div>
    </>
  );
}

function AppleButton({ onError }: { onError: (message: string) => void }) {
  const router = useRouter();
  const [scriptReady, setScriptReady] = useState(false);

  async function handleClick() {
    if (!window.AppleID) {
      onError('SDK Apple belum termuat, coba lagi sesaat.');
      return;
    }
    try {
      window.AppleID.auth.init({
        clientId: APPLE_CLIENT_ID,
        scope: 'name email',
        redirectURI: window.location.origin + '/login',
        usePopup: true,
      });
      const result = await window.AppleID.auth.signIn();
      const fullName = result.user?.name
        ? [result.user.name.firstName, result.user.name.lastName].filter(Boolean).join(' ')
        : undefined;

      const res = await fetch('/api/auth/apple', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identityToken: result.authorization.id_token, fullName }),
      });
      const data = await res.json();
      if (!res.ok) {
        onError(data.message ?? 'Masuk dengan Apple gagal.');
        return;
      }
      router.push('/tasks');
      router.refresh();
    } catch {
      // AppleID.auth.signIn() rejects silently if the user cancels the
      // popup — that's not an error worth surfacing.
    }
  }

  return (
    <>
      <Script
        src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js"
        strategy="afterInteractive"
        onReady={() => setScriptReady(true)}
      />
      <button
        type="button"
        onClick={handleClick}
        disabled={!scriptReady}
        className="flex w-full items-center justify-center gap-2 rounded-button border border-border bg-surface py-2.5 text-small font-medium text-text-primary shadow-sm transition hover:bg-background disabled:opacity-50"
      >
        <AppleLogoIcon />
        <span>Lanjutkan dengan Apple</span>
      </button>
    </>
  );
}
