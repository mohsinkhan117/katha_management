// Equivalent to Flutter's ProductRepository (lib/features/product/data/repositories/product_repository.dart)
// Handles all Supabase PostgreSQL queries for the Company's Master Product Catalog.

import { createClient } from "@/lib/supabase/client";

export interface CreateProductInput {
  company_id: string;
  name: string;
  sku: string;
  base_unit: string;
  base_price: number;
}

export const productService = {
  /**
   * Fetch all products belonging to the logged-in Company tenant.
   * Equivalent to: Future<List<ProductModel>> getProducts()
   */
  async getCompanyProducts(companyId: string) {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("products")
      .select("*, product_sizes(*)")
      .eq("company_id", companyId)
      .order("created_at", { ascending: false });

    if (error) throw new Error(error.message);
    return data ?? [];
  },

  /**
   * Insert a new product into Supabase. PowerSync automatically pushes it to Distributors.
   * Equivalent to: Future<void> addProduct(ProductModel product)
   */
  async createProduct(input: CreateProductInput) {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("products")
      .insert(input)
      .select()
      .single();

    if (error) throw new Error(error.message);
    return data;
  },
};

