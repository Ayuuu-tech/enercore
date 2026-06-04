import { Injectable, OnModuleInit } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
  private supabaseClient: SupabaseClient;

  onModuleInit() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_KEY;

    if (!supabaseUrl || !supabaseKey) {
      console.warn('Supabase URL or Key is missing in environment variables');
      return;
    }

    this.supabaseClient = createClient(supabaseUrl, supabaseKey);
    console.log('Supabase client initialized successfully.');
  }

  getClient(): SupabaseClient {
    return this.supabaseClient;
  }
}
