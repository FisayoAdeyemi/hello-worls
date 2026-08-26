CREATE OR REPLACE VIEW public.uk_sponsor_match_review AS
 SELECT s.id,
    s.display_name,
    s.primary_city,
    s.match_score,
    c.name AS matched_company,
    c.post_town,
    c.company_number
   FROM uk_sponsors s
     JOIN uk_companies c ON c.company_number = s.company_number
  WHERE s.match_method = 'trigram'::text AND s.match_score < 0.6
  ORDER BY s.match_score;
ALTER VIEW public.uk_sponsor_match_review SET (security_invoker=on);

CREATE OR REPLACE VIEW public.uk_sponsors_unmatched AS
 SELECT id,
    display_name,
    normalized_name,
    primary_city,
    routes,
    best_rating
   FROM uk_sponsors
  WHERE company_number IS NULL
  ORDER BY display_name;
ALTER VIEW public.uk_sponsors_unmatched SET (security_invoker=on);
