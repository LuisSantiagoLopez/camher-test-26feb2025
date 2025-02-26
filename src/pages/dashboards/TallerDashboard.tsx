import { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, FileText, Truck } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { Part, Unit } from '../../types';
import CreatePartModal from '../../components/modals/CreatePartModal';
import EditPartModal from '../../components/modals/EditPartModal';
import CreateUnitModal from '../../components/modals/CreateUnitModal';
import PartDetailsModal from '../../components/modals/PartDetailsModal';
import toast from 'react-hot-toast';

export default function TallerDashboard() {
  const [parts, setParts] = useState<Part[]>([]);
  const [units, setUnits] = useState<Unit[]>([]);
  const [isCreatePartModalOpen, setIsCreatePartModalOpen] = useState(false);
  const [isEditPartModalOpen, setIsEditPartModalOpen] = useState(false);
  const [isCreateUnitModalOpen, setIsCreateUnitModalOpen] = useState(false);
  const [selectedPart, setSelectedPart] = useState<Part | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchParts();
    fetchUnits();
  }, []);

  const fetchParts = async () => {
    try {
      const { data, error } = await supabase
        .from('parts')
        .select(`
          *,
          unit:units(name),
          provider:providers(name)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setParts(data || []);
    } catch (error: any) {
      console.error('Error fetching parts:', error);
      toast.error('Error al cargar las refacciones');
    } finally {
      setLoading(false);
    }
  };

  const fetchUnits = async () => {
    try {
      const { data, error } = await supabase
        .from('units')
        .select('*')
        .order('name');

      if (error) throw error;
      setUnits(data || []);
    } catch (error: any) {
      console.error('Error fetching units:', error);
      toast.error('Error al cargar las unidades');
    }
  };

  const handleEdit = (part: Part) => {
    // Solo permitir edición si el estatus es 0 o 1
    if (part.status >= 2 || part.status === -1) {
      toast.error('No se puede editar una refacción que ya está en revisión, cancelada o en un estado posterior');
      return;
    }
    setSelectedPart(part);
    setIsEditPartModalOpen(true);
  };

  const handleDelete = async (partId: string) => {
    if (!confirm('¿Estás seguro de eliminar esta refacción?')) return;

    try {
      const { error } = await supabase
        .from('parts')
        .delete()
        .eq('id', partId);

      if (error) throw error;
      
      toast.success('Refacción eliminada');
      fetchParts();
    } catch (error: any) {
      console.error('Error deleting part:', error);
      toast.error('Error al eliminar la refacción');
    }
  };

  const handleDeleteUnit = async (unitId: string) => {
    if (!confirm('¿Estás seguro de eliminar esta unidad? Esto eliminará también todas las refacciones asociadas.')) return;

    try {
      const { error } = await supabase
        .from('units')
        .delete()
        .eq('id', unitId);

      if (error) throw error;
      
      toast.success('Unidad eliminada');
      fetchUnits();
      fetchParts();
    } catch (error: any) {
      console.error('Error deleting unit:', error);
      toast.error('Error al eliminar la unidad');
    }
  };

  const handleViewDetails = (part: Part) => {
    setSelectedPart(part);
  };

  const getStatusBadgeColor = (status: number) => {
    switch (status) {
      case -1: return 'bg-red-100 text-red-800';
      case 0: return 'bg-gray-100 text-gray-800';
      case 1: return 'bg-blue-100 text-blue-800';
      case 2: return 'bg-yellow-100 text-yellow-800';
      case 3: return 'bg-purple-100 text-purple-800';
      case 4: return 'bg-green-100 text-green-800';
      case 5: return 'bg-pink-100 text-pink-800';
      case 6: return 'bg-emerald-100 text-emerald-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: number) => {
    switch (status) {
      case -1: return 'Cancelada';
      case 0: return 'Inicial/Rechazada';
      case 1: return 'Creada';
      case 2: return 'En revisión (Admin)';
      case 3: return 'En revisión (Proveedor)';
      case 4: return 'Esperando factura';
      case 5: return 'Esperando contrarecibo';
      case 6: return 'Completada';
      default: return 'Desconocido';
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-900">Gestión de Refacciones</h1>
        <div className="flex space-x-4">
          <button
            onClick={() => setIsCreateUnitModalOpen(true)}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            <Truck className="h-5 w-5 mr-2" />
            Nueva Unidad
          </button>
          <button
            onClick={() => setIsCreatePartModalOpen(true)}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            <Plus className="h-5 w-5 mr-2" />
            Nueva Refacción
          </button>
        </div>
      </div>

      {/* Units Section */}
      <div className="bg-white shadow overflow-hidden sm:rounded-lg">
        <div className="px-4 py-5 sm:px-6">
          <h2 className="text-lg font-medium text-gray-900">Unidades</h2>
          <p className="mt-1 text-sm text-gray-500">Lista de unidades disponibles</p>
        </div>
        <div className="border-t border-gray-200">
          <ul className="divide-y divide-gray-200">
            {units.map((unit) => (
              <li key={unit.id} className="px-4 py-4 sm:px-6 hover:bg-gray-50">
                <div className="flex items-center justify-between">
                  <div className="text-sm font-medium text-gray-900">{unit.name}</div>
                  <button
                    onClick={() => handleDeleteUnit(unit.id)}
                    className="text-red-600 hover:text-red-900"
                  >
                    <Trash2 className="h-5 w-5" />
                  </button>
                </div>
              </li>
            ))}
            {units.length === 0 && (
              <li className="px-4 py-4 sm:px-6 text-center text-gray-500">
                No hay unidades registradas
              </li>
            )}
          </ul>
        </div>
      </div>

      {/* Parts Section */}
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {parts.map((part) => (
            <li key={part.id} className="px-6 py-4 hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center space-x-3">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusBadgeColor(part.status)}`}>
                      {getStatusText(part.status)}
                    </span>
                    <p className="text-sm font-medium text-gray-900 truncate">
                      {part.description?.[0]}
                    </p>
                  </div>
                  <div className="mt-2 flex items-center text-sm text-gray-500 space-x-4">
                    <span>Unidad: {part.unit?.name}</span>
                    <span>Precio: ${part.price}</span>
                    {part.provider && <span>Proveedor: {part.provider.name}</span>}
                  </div>
                </div>
                <div className="flex items-center space-x-4">
                  {/* Solo mostrar botones de edición y eliminación si el estado es 0 o 1 */}
                  {(part.status === 0 || part.status === 1) && (
                    <>
                      <button
                        onClick={() => handleEdit(part)}
                        className="text-gray-400 hover:text-gray-500"
                        title="Editar refacción"
                      >
                        <Edit className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => handleDelete(part.id)}
                        className="text-red-400 hover:text-red-500"
                        title="Eliminar refacción"
                      >
                        <Trash2 className="h-5 w-5" />
                      </button>
                    </>
                  )}
                  <button
                    onClick={() => handleViewDetails(part)}
                    className="text-blue-400 hover:text-blue-500 cursor-pointer"
                    title="Ver detalles"
                  >
                    <FileText className="h-5 w-5" />
                  </button>
                </div>
              </div>
            </li>
          ))}
          {parts.length === 0 && (
            <li className="px-6 py-12 text-center text-gray-500">
              No hay refacciones registradas
            </li>
          )}
        </ul>
      </div>

      {isCreatePartModalOpen && (
        <CreatePartModal
          units={units}
          onClose={() => setIsCreatePartModalOpen(false)}
          onSuccess={() => {
            setIsCreatePartModalOpen(false);
            fetchParts();
          }}
        />
      )}

      {isEditPartModalOpen && selectedPart && (
        <EditPartModal
          part={selectedPart}
          units={units}
          onClose={() => {
            setIsEditPartModalOpen(false);
            setSelectedPart(null);
          }}
          onSuccess={() => {
            setIsEditPartModalOpen(false);
            setSelectedPart(null);
            fetchParts();
          }}
        />
      )}

      {isCreateUnitModalOpen && (
        <CreateUnitModal
          onClose={() => setIsCreateUnitModalOpen(false)}
          onSuccess={() => {
            setIsCreateUnitModalOpen(false);
            fetchUnits();
          }}
        />
      )}

      {selectedPart && !isEditPartModalOpen && (
        <PartDetailsModal
          part={selectedPart}
          onClose={() => setSelectedPart(null)}
        />
      )}
    </div>
  );
}