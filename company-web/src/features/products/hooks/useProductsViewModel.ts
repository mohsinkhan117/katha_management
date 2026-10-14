"use client";

// Equivalent to Flutter's AddProductViewModel / ProductListViewModel (ChangeNotifier)
// Manages state (isLoading, error, products list) and exposes actions to the View.

import { useState, useCallback } from "react";
import { productService, CreateProductInput } from "../services/productService";

export function useProductsViewModel(companyId: string) {
  const [products, setProducts] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Equivalent to viewModel.loadProducts() + notifyListeners()
  const loadProducts = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const data = await productService.getCompanyProducts(companyId);
      setProducts(data);
    } catch (err: any) {
      setErrorMessage(err.message ?? "Failed to load products");
    } finally {
      setIsLoading(false);
    }
  }, [companyId]);

  // Equivalent to viewModel.addProduct(...) + notifyListeners()
  const addProduct = useCallback(
    async (input: Omit<CreateProductInput, "company_id">) => {
      setIsLoading(true);
      setErrorMessage(null);
      try {
        await productService.createProduct({ ...input, company_id: companyId });
        await loadProducts();
        return true;
      } catch (err: any) {
        setErrorMessage(err.message ?? "Failed to create product");
        return false;
      } finally {
        setIsLoading(false);
      }
    },
    [companyId, loadProducts]
  );

  return {
    products,
    isLoading,
    errorMessage,
    loadProducts,
    addProduct,
  };
}

