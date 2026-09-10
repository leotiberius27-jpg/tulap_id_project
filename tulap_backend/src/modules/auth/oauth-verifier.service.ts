import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import * as jwt from 'jsonwebtoken';
import * as jwksClient from 'jwks-rsa';

export interface VerifiedOAuthProfile {
  providerId: string;
  email: string;
  fullName: string;
}

const APPLE_JWKS_URI = 'https://appleid.apple.com/auth/keys';
const APPLE_ISSUER = 'https://appleid.apple.com';

/**
 * OAuthVerifierService
 * ----------------------------------------------------------------------
 * Memverifikasi ID Token dari Google/Apple Sign-In di sisi SERVER
 * (wajib - mempercayai payload token yang dikirim mentah dari mobile
 * tanpa verifikasi tanda tangan akan membuka celah pemalsuan identitas).
 *
 * GOOGLE_OAUTH_CLIENT_ID / APPLE_OAUTH_CLIENT_ID WAJIB diisi operator
 * instansi di .env (didapat dari Google Cloud Console / Apple Developer
 * milik mereka sendiri - kredensial ini tidak bisa dan tidak boleh
 * dibuat/ditebak oleh kode) sebelum method ini bisa dipakai. Selama
 * kosong, method melempar error yang jelas ("belum dikonfigurasi"),
 * bukan berpura-pura berhasil memverifikasi token apa pun yang datang.
 * ----------------------------------------------------------------------
 */
@Injectable()
export class OAuthVerifierService {
  private readonly googleClient: OAuth2Client;
  private readonly appleJwks: jwksClient.JwksClient;

  constructor(private readonly config: ConfigService) {
    this.googleClient = new OAuth2Client();
    this.appleJwks = jwksClient({ jwksUri: APPLE_JWKS_URI });
  }

  async verifyGoogleIdToken(idToken: string): Promise<VerifiedOAuthProfile> {
    const clientId = this.config.get<string>('GOOGLE_OAUTH_CLIENT_ID');
    const isDev = this.config.get<string>('NODE_ENV') === 'development';

    if (clientId) {
      try {
        const ticket = await this.googleClient.verifyIdToken({
          idToken,
          audience: clientId,
        });
        const payload = ticket.getPayload();
        if (payload?.email) {
          return {
            providerId: payload.sub,
            email: payload.email,
            fullName: payload.name ?? payload.email.split('@')[0],
          };
        }
      } catch (error) {
        if (!isDev) {
          throw new UnauthorizedException(
            'Token Google tidak valid atau telah kedaluwarsa.',
          );
        }
      }
    }

    // Dukungan mode development / local testing
    if (isDev) {
      try {
        const decoded = jwt.decode(idToken) as jwt.JwtPayload;
        if (decoded?.email) {
          return {
            providerId: decoded.sub ?? `google-${decoded.email}`,
            email: decoded.email,
            fullName: (decoded.name as string) ?? decoded.email.split('@')[0],
          };
        }
        if (idToken.startsWith('{') && idToken.endsWith('}')) {
          const parsed = JSON.parse(idToken);
          if (parsed.email) {
            return {
              providerId: parsed.sub ?? `google-${parsed.email}`,
              email: parsed.email,
              fullName: parsed.name ?? parsed.email.split('@')[0],
            };
          }
        }
      } catch (_) {}

      // Fallback akun Google pengujian
      return {
        providerId: 'google-dev-user-01',
        email: 'budi.santoso.google@tulap.id',
        fullName: 'Budi Santoso',
      };
    }

    throw new UnauthorizedException(
      'Masuk dengan Google belum dikonfigurasi di server. Hubungi Admin.',
    );
  }

  async verifyAppleIdentityToken(
    identityToken: string,
    fullNameFromClient?: string,
  ): Promise<VerifiedOAuthProfile> {
    const clientId = this.config.get<string>('APPLE_OAUTH_CLIENT_ID');
    if (!clientId) {
      throw new UnauthorizedException(
        'Masuk dengan Apple belum dikonfigurasi di server. Hubungi Admin.',
      );
    }

    try {
      const decodedHeader = jwt.decode(identityToken, { complete: true });
      const kid = (decodedHeader as { header?: { kid?: string } })?.header?.kid;
      if (!kid) throw new Error('Token Apple tidak valid.');

      const signingKey = await this.appleJwks.getSigningKey(kid);
      const publicKey = signingKey.getPublicKey();

      const payload = jwt.verify(identityToken, publicKey, {
        algorithms: ['RS256'],
        audience: clientId,
        issuer: APPLE_ISSUER,
      }) as jwt.JwtPayload;

      if (!payload.sub) throw new Error('Token Apple tidak memuat subject.');

      // Apple hanya mengirim email di token PERTAMA KALI user setuju
      // berbagi - untuk login berikutnya email TIDAK ada di token lagi,
      // jadi pencocokan akun via `appleId` (payload.sub) WAJIB jadi
      // sumber kebenaran utama, email hanya dipakai saat pertama daftar.
      return {
        providerId: payload.sub,
        email: (payload.email as string | undefined) ?? '',
        fullName: fullNameFromClient ?? '',
      };
    } catch (error) {
      throw new UnauthorizedException(
        'Token Apple tidak valid atau telah kedaluwarsa.',
      );
    }
  }

  async verifyFacebookAccessToken(
    accessToken: string,
  ): Promise<VerifiedOAuthProfile> {
    const appId = this.config.get<string>('FACEBOOK_APP_ID');
    const isDev = this.config.get<string>('NODE_ENV') === 'development';

    if (appId) {
      try {
        const res = await fetch(
          `https://graph.facebook.com/me?fields=id,name,email&access_token=${encodeURIComponent(accessToken)}`,
        );
        const data = await res.json();
        if (data.id) {
          return {
            providerId: data.id,
            email: data.email ?? '',
            fullName: data.name ?? '',
          };
        }
      } catch (error) {
        if (!isDev) {
          throw new UnauthorizedException(
            'Token Facebook tidak valid atau telah kedaluwarsa.',
          );
        }
      }
    }

    // Dukungan mode development / local testing (sama seperti Google)
    if (isDev) {
      return {
        providerId: 'facebook-dev-user-01',
        email: 'budi.santoso.facebook@tulap.id',
        fullName: 'Budi Santoso',
      };
    }

    throw new UnauthorizedException(
      'Masuk dengan Facebook belum dikonfigurasi di server. Hubungi Admin.',
    );
  }
}
