-- ============================================================
-- Finger Board — Supabase データベーススキーマ
-- ============================================================
-- 実行順序: 上から順に Supabase SQL Editor に貼り付けて実行
-- ============================================================

-- ── 拡張機能 ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. ユーザープロファイル（Supabase Auth の auth.users を拡張）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  role        TEXT NOT NULL DEFAULT 'teacher'  -- 'teacher' | 'student'
              CHECK (role IN ('teacher', 'student')),
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. 教材ドキュメント（旧: .mun ファイル 1つ ≒ 1ドキュメント）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.documents (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL DEFAULT '無題の教材',
  -- ページの順序（page id の配列）
  page_order  UUID[] NOT NULL DEFAULT '{}',
  -- 設定
  settings    JSONB NOT NULL DEFAULT '{
    "dedicated_size": {"width": 1024, "height": 768},
    "server_enabled": false
  }',
  -- ソフト削除
  is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. ページ（旧: SavedPageData / .mun の内側オブジェクト）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.pages (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doc_id      UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  -- 旧: pageTitle
  title       TEXT NOT NULL DEFAULT '',
  -- 旧: objectsData（配列を JSONB で保存）
  objects_data JSONB NOT NULL DEFAULT '[]',
  -- 旧: animationData
  animation_data JSONB NOT NULL DEFAULT '{}',
  -- マスターページ参照（旧: masterId）
  master_id   UUID REFERENCES public.pages(id) ON DELETE SET NULL,
  -- 旧: pageOptions
  page_options JSONB NOT NULL DEFAULT '{
    "studentsModWarning": false,
    "forceStudentsMode": false,
    "vars": {},
    "customEvents": {}
  }',
  -- check_on（解答表示状態）
  check_on    BOOLEAN NOT NULL DEFAULT FALSE,
  -- カスタムマスターオブジェクト
  custom_master_data JSONB NOT NULL DEFAULT '{}',
  -- ページストックオブジェクト
  page_stock_objects JSONB NOT NULL DEFAULT '{}',
  -- アセット参照（Supabase Storage のパス）
  assets_sound TEXT[] NOT NULL DEFAULT '{}',
  assets_image TEXT[] NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 4. インポート履歴（.mun からの移行追跡）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.import_history (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  doc_id      UUID REFERENCES public.documents(id) ON DELETE SET NULL,
  -- 元ファイル情報
  original_filename TEXT NOT NULL,
  original_file_size INTEGER,
  -- 変換結果
  status      TEXT NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'processing', 'success', 'failed')),
  error_message TEXT,
  page_count  INTEGER DEFAULT 0,
  object_count INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 5. クラス共有（教師→生徒へのドキュメント共有）
-- ============================================================
CREATE TABLE IF NOT EXISTS public.document_shares (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doc_id      UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  shared_by   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  shared_with UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  permission  TEXT NOT NULL DEFAULT 'read'
              CHECK (permission IN ('read', 'write')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(doc_id, shared_with)
);

-- ============================================================
-- インデックス
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_documents_owner ON public.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_updated ON public.documents(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_pages_doc_id ON public.pages(doc_id);
CREATE INDEX IF NOT EXISTS idx_import_history_owner ON public.import_history(owner_id);

-- ============================================================
-- updated_at 自動更新トリガー
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_documents_updated_at
  BEFORE UPDATE ON public.documents
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_pages_updated_at
  BEFORE UPDATE ON public.pages
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- Row Level Security (RLS) — 自分のデータだけアクセス可
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.import_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_shares ENABLE ROW LEVEL SECURITY;

-- profiles: 自分自身のみ読み書き
CREATE POLICY "profiles_self" ON public.profiles
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- documents: オーナーまたは共有相手が読み書き
CREATE POLICY "documents_owner" ON public.documents
  FOR ALL USING (
    auth.uid() = owner_id
    OR EXISTS (
      SELECT 1 FROM public.document_shares
      WHERE doc_id = documents.id AND shared_with = auth.uid()
    )
  );

-- pages: ドキュメントへのアクセス権がある人が読み書き
CREATE POLICY "pages_via_document" ON public.pages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.id = pages.doc_id
        AND (
          d.owner_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.document_shares s
            WHERE s.doc_id = d.id AND s.shared_with = auth.uid()
          )
        )
    )
  );

-- import_history: 自分のみ
CREATE POLICY "import_history_self" ON public.import_history
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- document_shares: 共有した人または共有された人
CREATE POLICY "document_shares_access" ON public.document_shares
  USING (auth.uid() = shared_by OR auth.uid() = shared_with);

-- ============================================================
-- 新規ユーザー登録時にプロファイルを自動作成
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email, 'ユーザー')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Supabase Storage バケット（アプリのファイルアップロード先）
-- ============================================================
-- Dashboard > Storage で手動作成してください:
--   バケット名: "finger-board-assets"
--   Public: false（認証必須）
-- ============================================================
