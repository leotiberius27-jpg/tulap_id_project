import { RoleName } from '@prisma/client';

/**
 * Bentuk data user yang tersedia di `request.user` setelah token JWT
 * berhasil divalidasi oleh JwtStrategy. Hanya berisi data minimal &
 * tidak sensitif (TIDAK menyertakan passwordHash).
 */
export interface AuthenticatedUser {
  id: string;
  email: string;
  fullName: string;
  role: RoleName;
  instansiName: string | null;
}

/**
 * Bentuk payload yang di-encode ke dalam JWT token.
 */
export interface JwtPayload {
  sub: string; // User ID (subject)
  email: string;
  role: RoleName;
}
