-- 0002 — Version mobile hors connexion (D-16, F-38, RG-30)
-- Une contribution préparée hors connexion porte un identifiant attribué par l'appareil (idempotence des envois)
-- et la date à laquelle elle a été rédigée. Elle n'est enregistrée qu'à sa réception : les règles RG-20 à RG-26
-- s'appliquent alors normalement (déclencheur contribution_controler).

ALTER TABLE contribution
  ADD COLUMN id_client uuid,
  ADD COLUMN saisie_le timestamptz;

CREATE UNIQUE INDEX ux_contribution_id_client ON contribution (id_client) WHERE id_client IS NOT NULL;

ALTER TABLE contribution
  ADD CONSTRAINT ck_contribution_hors_ligne CHECK (
    source = 'EN_LIGNE' OR (id_client IS NULL AND saisie_le IS NULL)),
  ADD CONSTRAINT ck_contribution_saisie CHECK (
    saisie_le IS NULL OR saisie_le <= deposee_le + interval '5 minutes');

COMMENT ON COLUMN contribution.id_client IS 'Identifiant attribué par l''appareil à une contribution préparée dans la version mobile ; un nouvel envoi de la même contribution est reconnu et ne crée pas de doublon (RG-30)';
COMMENT ON COLUMN contribution.saisie_le IS 'Date de rédaction sur l''appareil pour une contribution préparée hors connexion ; la date d''enregistrement reste deposee_le (RG-30)';
