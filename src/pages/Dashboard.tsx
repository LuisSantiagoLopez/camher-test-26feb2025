import React from 'react';
import { useAuthStore } from '../store/authStore';
import TallerDashboard from './dashboards/TallerDashboard';
import AdminDashboard from './dashboards/AdminDashboard';
import ProveedorDashboard from './dashboards/ProveedorDashboard';
import ContadorDashboard from './dashboards/ContadorDashboard';

export default function Dashboard() {
  const { profile } = useAuthStore();

  if (!profile?.is_approved) {
    return (
      <div className="text-center py-12">
        <h2 className="text-2xl font-bold text-gray-900 mb-4">Cuenta en Revisión</h2>
        <p className="text-gray-600">
          Tu cuenta está pendiente de aprobación por un administrador.
          Te notificaremos cuando tu cuenta sea aprobada.
        </p>
      </div>
    );
  }

  switch (profile.role) {
    case 'taller':
      return <TallerDashboard />;
    case 'admin':
      return <AdminDashboard />;
    case 'proveedor':
      return <ProveedorDashboard />;
    case 'contador':
      return <ContadorDashboard />;
    default:
      return <div>Rol no válido</div>;
  }
}