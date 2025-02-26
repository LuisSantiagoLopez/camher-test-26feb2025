import React from 'react';
import { useAuthStore } from '../store/authStore';
import { AlertTriangle } from 'lucide-react';

interface ProviderVerificationProps {
  providerId: string | null;
  children: React.ReactNode;
}

export default function ProviderVerification({ providerId, children }: ProviderVerificationProps) {
  const { profile } = useAuthStore();

  // Verificar que el usuario es un proveedor aprobado
  if (!profile || profile.role !== 'proveedor' || !profile.is_approved) {
    return (
      <div className="bg-red-50 border-l-4 border-red-400 p-4">
        <div className="flex">
          <div className="flex-shrink-0">
            <AlertTriangle className="h-5 w-5 text-red-400" />
          </div>
          <div className="ml-3">
            <h3 className="text-sm font-medium text-red-800">
              Acceso No Autorizado
            </h3>
            <div className="mt-2 text-sm text-red-700">
              <p>No tienes permisos para ver esta información.</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Verificar que el proveedor está asignado a la refacción
  if (!providerId) {
    return (
      <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4">
        <div className="flex">
          <div className="flex-shrink-0">
            <AlertTriangle className="h-5 w-5 text-yellow-400" />
          </div>
          <div className="ml-3">
            <h3 className="text-sm font-medium text-yellow-800">
              Refacción No Asignada
            </h3>
            <div className="mt-2 text-sm text-yellow-700">
              <p>Esta refacción no está asignada a ningún proveedor.</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}