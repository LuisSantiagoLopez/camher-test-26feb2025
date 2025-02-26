import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import type { Profile } from '../types';

interface AuthState {
  profile: Profile | null;
  loading: boolean;
  error: string | null;
  setProfile: (profile: Profile | null) => void;
  setError: (error: string | null) => void;
  fetchProfile: () => Promise<void>;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  profile: null,
  loading: true,
  error: null,
  setProfile: (profile) => set({ profile }),
  setError: (error) => set({ error }),
  clearError: () => set({ error: null }),
  fetchProfile: async () => {
    try {
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      
      if (userError) {
        // Don't treat session missing as an error
        if (userError.name === 'AuthSessionMissingError') {
          set({ profile: null, loading: false });
          return;
        }
        console.error('Error fetching user:', userError);
        set({ profile: null, loading: false, error: userError.message });
        return;
      }

      if (!user) {
        set({ profile: null, loading: false });
        return;
      }

      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (profileError) {
        console.error('Error fetching profile:', profileError);
        set({ profile: null, loading: false, error: profileError.message });
        return;
      }

      set({ profile, loading: false, error: null });
    } catch (error: any) {
      console.error('Unexpected error in fetchProfile:', error);
      set({ 
        profile: null, 
        loading: false, 
        error: error.message || 'An unexpected error occurred'
      });
    }
  },
}));