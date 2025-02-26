import React from 'react';
import { X } from 'lucide-react';

interface PartDescriptionListProps {
  descriptions: string[];
  unitaryPrices: number[];
  quantities: number[];
  setFormData: (data: any) => void;
}

const PartDescriptionList: React.FC<PartDescriptionListProps> = ({
  descriptions,
  unitaryPrices,
  quantities,
  setFormData,
}) => {
  const handleAddDescription = () => {
    setFormData((prev: any) => ({
      ...prev,
      description: [...prev.description, ''],
      unitary_price: [...prev.unitary_price, 0],
      quantity: [...prev.quantity, 1],
    }));
  };

  const handleRemoveDescription = (index: number) => {
    setFormData((prev: any) => ({
      ...prev,
      description: prev.description.filter((_: any, i: number) => i !== index),
      unitary_price: prev.unitary_price.filter((_: any, i: number) => i !== index),
      quantity: prev.quantity.filter((_: any, i: number) => i !== index),
    }));
  };

  const updateDescription = (index: number, value: string) => {
    const newDescriptions = [...descriptions];
    newDescriptions[index] = value;
    setFormData((prev: any) => ({ ...prev, description: newDescriptions }));
  };

  const updateUnitaryPrice = (index: number, value: string) => {
    const newPrices = [...unitaryPrices];
    const numericValue = parseFloat(value) || 0;
    newPrices[index] = numericValue;
    setFormData((prev: any) => ({
      ...prev,
      unitary_price: newPrices,
      price: newPrices.reduce((acc, price, i) => acc + price * quantities[i], 0),
    }));
  };

  const updateQuantity = (index: number, value: string) => {
    const newQuantities = [...quantities];
    const numericValue = parseInt(value) || 1;
    newQuantities[index] = numericValue;
    setFormData((prev: any) => ({
      ...prev,
      quantity: newQuantities,
      price: unitaryPrices.reduce((acc, price, i) => acc + price * newQuantities[i], 0),
    }));
  };

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <label className="block text-sm font-medium text-gray-700">Refacciones</label>
        <button
          type="button"
          onClick={handleAddDescription}
          className="text-sm text-blue-600 hover:text-blue-500"
        >
          + Agregar refacción
        </button>
      </div>
      {descriptions.map((desc, index) => (
        <div key={index} className="flex gap-4 items-start">
          <div className="flex-1">
            <input
              type="text"
              required
              value={desc}
              onChange={(e) => updateDescription(index, e.target.value)}
              placeholder="Descripción de la refacción"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>
          <div className="w-32">
            <input
              type="number"
              required
              min="0"
              step="0.01"
              value={unitaryPrices[index].toString()}
              onChange={(e) => updateUnitaryPrice(index, e.target.value)}
              placeholder="Precio unitario"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>
          <div className="w-24">
            <input
              type="number"
              required
              min="1"
              value={quantities[index].toString()}
              onChange={(e) => updateQuantity(index, e.target.value)}
              placeholder="Cantidad"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>
          {index > 0 && (
            <button
              type="button"
              onClick={() => handleRemoveDescription(index)}
              className="mt-1 text-red-600 hover:text-red-500"
            >
              <X className="h-5 w-5" />
            </button>
          )}
        </div>
      ))}
    </div>
  );
};

export default PartDescriptionList;