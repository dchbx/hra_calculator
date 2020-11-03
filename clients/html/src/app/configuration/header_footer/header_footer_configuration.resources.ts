interface HeaderFooterColorSettings {
  [key: string]: any;
  primary_color?: string | null;
  typeface_url?: string | null;
  typeface_name?: string | null;
}

export interface HeaderFooterConfigurationResource {
  [key: string]: any;
  colors?: HeaderFooterColorSettings | null;
  site_logo?: string | null;
  marketplace_name?: string;
  marketplace_website_url?: string | null;
  call_center_phone?: string | null;
  benefit_year?: string | null;
  show_plan_in_results?: boolean | null;
}
