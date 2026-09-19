-- declare-observe-provider-observability.sql
--
-- The observe frame's provider observability, authored as rows. The equity
-- observe display (declare-equity-observe-display.sql) renders the declared
-- story; its WHEN lane and TRACE entries name each exchange responsibility but
-- carry none of the fact the exchange actually produced, so a 429 quota
-- rejection is indistinguishable from any other retention and the route that
-- answered is unnamed. This migration declares the missing facts where they
-- belong and renders them from declared data only:
--
--   1. providerAuthorities on the two exchange port bindings. The endpoint
--      authority records already declare providerId/bindingId (the fallback
--      record in add-equity-price-fallback-route.sql; the primary's canonical
--      binding in the capability's normalize transformation and interfaces
--      authority). The port binding is the declared place the graph source
--      reaches: ports select the newest included definition, so minting a new
--      definition is the whole change and no execution authority moves.
--   2. The display transformation re-declares its expression to join, per
--      exchange operation, the declared port binding (provider identity and
--      endpoint prefix) with the provider-altitude testimony (bounded
--      providerEvidence). Each exchange cell's entry carries a note:
--
--        provider <providerId> · binding <bindingId> · endpoint <urlPrefix>
--          · exchange <outcomeVariant> · reason <scenario reasonCode>
--          · stage <reachedStage> · calls <exchangeCount>
--          · transport <transportDisposition> · redacted <redactionVerified>
--          · http <httpStatus>
--
--      Names facts, never prose: every value is a declared scalar the display
--      scope already contains. The note attaches only when the provider
--      testimony carries bounded providerEvidence, so the credential-binding
--      descent (which carries none) stays unnamed and the hello path (no
--      exchange cells) is untouched. Both readings render it: the WHEN lane in
--      default and trace, the provider/physical tree entries in trace.
--
-- The kernel bound that carries httpStatus in providerEvidence is SDA request
-- 11 (docs/sda-change-request-bounded-provider-evidence-http-status.md); the
-- field simply does not render before that bound lands.
--
-- Idempotent: content-addressed definitions; a replay selects the same
-- definitions and mints nothing.
--
-- Default: ROLLBACK. Replace the final ROLLBACK TRANSACTION; with COMMIT
-- TRANSACTION; to install (after the from-transaction preflight passes).
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
GO
DECLARE @namespace nvarchar(400)=N'sidefx:capability:resolve-equity-market-price-evidence';

-- ============================== 1. DECLARED PROVIDER IDENTITY ON THE EXCHANGE PORTS ==============================
-- The complete port inventory (the nine root ports and the five route ports)
-- with providerAuthorities added to the two governed-http exchange ports. The
-- endpoint authority entries are unchanged: the content address of the endpoint
-- record must keep naming exactly the record that grants the route, so provider
-- identity is declared beside it, never inside it.
DECLARE @port_bindings nvarchar(max)=CONVERT(nvarchar(max),N'[{"portId":"resolve-equity-market-price-evidence-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"transform-resolve-equity-market-price-evidence"}},{"portId":"retain-provider-realization-outside-market-price-semantics-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"retain-provider-realization-outside-market-price-semantics-preserve"}},{"portId":"hold-unavailable-equity-market-price-provider-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"hold-unavailable-equity-market-price-provider-preserve"}},{"portId":"reject-nonconforming-native-market-price-testimony-port","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"reject-nonconforming-native-market-price-testimony-preserve"}},{"portId":"build-equity-price-binding-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-equity-price-binding-request"}},{"portId":"bind-equity-price-provider-credential","platformCapabilityId":"sda-external-credential-reference-binding-port.v1","configuration":{"credentialAuthorities":[{"effectScopes":["ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"],"endpointAuthorityDigests":["sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"],"injectionRule":{"headerName":"X-RapidAPI-Key","id":"rapidapi-x-rapidapi-key.v1"},"lifetimeMilliseconds":15000,"referenceName":"RAPID_API_KEY","requestingCapabilityIds":["resolve-equity-market-price-evidence"],"source":"vault","storeLocator":"%LOCALAPPDATA%\\sfx\\vault"}]}},{"portId":"build-equity-price-exchange-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-equity-price-exchange-request"}},{"portId":"observe-equity-price-exchange","platformCapabilityId":"sda-governed-http-exchange-port.v1","configuration":{"credentialInjectionRules":[{"headerName":"X-RapidAPI-Key","id":"rapidapi-x-rapidapi-key.v1"}],"endpointAuthorities":[{"allowedRequestHeaders":["x-rapidapi-host"],"allowedResponseHeaders":["content-type","retry-after"],"endpointAuthorityDigest":"sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b","methods":["GET"],"urlPrefixes":["https://yahoo-finance166.p.rapidapi.com/api/stock/get-price?"]}],"providerAuthorities":[{"providerId":"rapidapi/davethebeast/yahoo-finance166","bindingId":"rapidapi-davethebeast-yahoo-finance166-stock-price.v1","endpointAuthorityDigest":"sha256:09ecb038af10e553a16ec517857dc1eaf9efd4a6e1e608bc47fb4ca27e947f9b"}]}},{"portId":"normalize-equity-price-evidence","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"normalize-equity-price-evidence"}},{"portId":"build-fallback-price-binding-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-fallback-price-binding-request"}},{"portId":"bind-fallback-price-provider-credential","platformCapabilityId":"sda-external-credential-reference-binding-port.v1","configuration":{"credentialAuthorities":[{"effectScopes":["ONE_BOUNDED_HTTPS_EXCHANGE_NO_REDIRECT_NO_RETRY"],"endpointAuthorityDigests":["sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769"],"injectionRule":{"headerName":"X-RapidAPI-Key","id":"rapidapi-x-rapidapi-key.v1"},"lifetimeMilliseconds":15000,"referenceName":"RAPID_API_KEY","requestingCapabilityIds":["resolve-equity-market-price-evidence"],"source":"vault","storeLocator":"%LOCALAPPDATA%\\sfx\\vault"}]}},{"portId":"build-fallback-price-exchange-request","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"build-fallback-price-exchange-request"}},{"portId":"observe-fallback-price-exchange","platformCapabilityId":"sda-governed-http-exchange-port.v1","configuration":{"credentialInjectionRules":[{"headerName":"X-RapidAPI-Key","id":"rapidapi-x-rapidapi-key.v1"}],"endpointAuthorities":[{"allowedRequestHeaders":["x-rapidapi-host"],"allowedResponseHeaders":["content-type","retry-after"],"endpointAuthorityDigest":"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769","methods":["GET"],"urlPrefixes":["https://yahoo-finance-real-time1.p.rapidapi.com/market/get-quotes?"]}],"providerAuthorities":[{"providerId":"rapidapi/yahoo-finance-real-time1","bindingId":"rapidapi-yahoo-finance-real-time1-market-quotes.v1","endpointAuthorityDigest":"sha256:17bd0ab8347e100f7987de6b1a0144d3555c43aea73fedf90786030593a76769"}]}},{"portId":"select-equity-price-route","platformCapabilityId":"sda-authority-transformation-port.v1","configuration":{"transformationAuthorityRef":"semantic-transformation.authority.json","transformationId":"select-equity-price-route"}}]');
DECLARE @port_id nvarchar(400), @binding nvarchar(max), @port bigint, @port_version bigint;
DECLARE @object bigint, @definition bigint, @digest binary(32);
DECLARE @ports TABLE (port_id nvarchar(400) COLLATE Latin1_General_100_BIN2 PRIMARY KEY, port_version_pk bigint);
DECLARE @port_cursor CURSOR;
SET @port_cursor = CURSOR LOCAL FAST_FORWARD FOR SELECT JSON_VALUE(value, '$.portId'), value FROM OPENJSON(@port_bindings);
OPEN @port_cursor;
FETCH NEXT FROM @port_cursor INTO @port_id, @binding;
WHILE @@FETCH_STATUS = 0 BEGIN
  EXEC model.put_semantic_definition 'PORT', @namespace, @port_id, @binding, @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
  SET @port = (SELECT port_pk FROM model.port WHERE semantic_object_pk = @object);
  IF @port IS NULL BEGIN
    INSERT model.port(namespace_pk, port_id, semantic_object_pk, object_kind)
    SELECT namespace_pk, @port_id, @object, 'PORT' FROM model.semantic_object WHERE semantic_object_pk = @object;
    SET @port = SCOPE_IDENTITY();
  END;
  SET @port_version = (SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk = @definition);
  IF @port_version IS NULL BEGIN
    INSERT model.port_version(port_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, port_profile, object_kind, _owner_definition_pk, _canonical_pointer)
    VALUES(@port, @object, @definition, @digest, 'consumer-interface-authority.v1', 'PORT', @definition, N'');
    SET @port_version = SCOPE_IDENTITY();
  END;
  INSERT @ports VALUES(@port_id, @port_version);
  FETCH NEXT FROM @port_cursor INTO @port_id, @binding;
END;
CLOSE @port_cursor;
DEALLOCATE @port_cursor;

-- ============================== 2. THE DECLARED DISPLAY TRANSFORMATION ==============================
DECLARE @transformationId nvarchar(400)=N'resolve-equity-market-price-evidence-observe-display.v1';
DECLARE @semantics nvarchar(max)=N'{"id":"resolve-equity-market-price-evidence-observe-display.v1","expression":{"op":"let","bindings":{"scenario":{"op":"path","from":"authority","path":"scenarios.0"},"authorityEntry":{"op":"path","from":"authority","path":"executionAuthorities.0"},"operations":{"op":"path","from":"authorityEntry","path":"operations"},"cells":{"op":"path","from":"plan","path":"canonicalGraph.cells"},"testimony":{"op":"path","from":"execution","path":"cellTestimony"},"domainOutcome":{"op":"path","from":"execution","path":"outcome"},"payload":{"op":"path","from":"domainOutcome","path":"payload"},"reasonCode":{"op":"path","from":"domainOutcome","path":"reasonCode"},"resolved":{"op":"equals","left":{"op":"path","from":"domainOutcome","path":"disposition"},"right":{"op":"literal","value":"EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED"}},"exchangeNotCompleted":{"op":"equals","left":{"op":"path","from":"reasonCode","path":""},"right":{"op":"literal","value":"PROVIDER_EXCHANGE_NOT_COMPLETED"}},"outcomeStatus":{"op":"if","when":{"op":"path","from":"resolved","path":""},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"domainOutcome","path":"disposition"},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"exchangeEntries":{"op":"map","from":{"op":"path","from":"operations","path":""},"as":"operation","value":{"op":"let","bindings":{"providerCell":{"op":"find","from":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"candidate","where":{"op":"equals","left":{"op":"path","from":"candidate","path":"execution.configuration.portId"},"right":{"op":"path","from":"operation","path":"portId"}}},"as":"providerCandidate","where":{"op":"equals","left":{"op":"path","from":"providerCandidate","path":"altitude"},"right":{"op":"literal","value":"provider"}}},"physicalCell":{"op":"find","from":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"candidate2","where":{"op":"equals","left":{"op":"path","from":"candidate2","path":"execution.configuration.portId"},"right":{"op":"path","from":"operation","path":"portId"}}},"as":"physicalCandidate","where":{"op":"equals","left":{"op":"path","from":"physicalCandidate","path":"altitude"},"right":{"op":"literal","value":"physical"}}},"providerObserved":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"providerFact","where":{"op":"equals","left":{"op":"path","from":"providerFact","path":"cellId"},"right":{"op":"path","from":"providerCell","path":"cellId"}}},"evidence":{"op":"path","from":"providerObserved","path":"providerEvidence"},"declared":{"op":"path","from":"providerCell","path":"execution.configuration.binding.configuration.providerAuthorities.0"},"endpoint":{"op":"path","from":"providerCell","path":"execution.configuration.binding.configuration.endpointAuthorities.0.urlPrefixes.0"},"hasEvidence":{"op":"path","from":"evidence","path":""},"facts":{"op":"if","when":{"op":"path","from":"hasEvidence","path":""},"then":{"op":"array","items":[{"op":"if","when":{"op":"path","from":"declared","path":"providerId"},"then":{"op":"format","template":"provider {value}","values":{"value":{"op":"path","from":"declared","path":"providerId"}}},"else":{"op":"literal","value":null}},{"op":"if","when":{"op":"path","from":"declared","path":"bindingId"},"then":{"op":"format","template":"binding {value}","values":{"value":{"op":"path","from":"declared","path":"bindingId"}}},"else":{"op":"literal","value":null}},{"op":"if","when":{"op":"path","from":"endpoint","path":""},"then":{"op":"format","template":"endpoint {value}","values":{"value":{"op":"path","from":"endpoint","path":""}}},"else":{"op":"literal","value":null}},{"op":"format","template":"exchange {value}","values":{"value":{"op":"path","from":"providerObserved","path":"outcomeVariant"}}},{"op":"if","when":{"op":"equals","left":{"op":"path","from":"reasonCode","path":""},"right":{"op":"literal","value":null}},"then":{"op":"literal","value":null},"else":{"op":"format","template":"reason {value}","values":{"value":{"op":"path","from":"reasonCode","path":""}}}},{"op":"if","when":{"op":"path","from":"hasEvidence","path":""},"then":{"op":"format","template":"stage {value}","values":{"value":{"op":"path","from":"evidence","path":"reachedStage"}}},"else":{"op":"literal","value":null}},{"op":"if","when":{"op":"path","from":"hasEvidence","path":""},"then":{"op":"format","template":"calls {value}","values":{"value":{"op":"path","from":"evidence","path":"exchangeCount"}}},"else":{"op":"literal","value":null}},{"op":"if","when":{"op":"path","from":"hasEvidence","path":""},"then":{"op":"format","template":"transport {value}","values":{"value":{"op":"path","from":"evidence","path":"transportDisposition"}}},"else":{"op":"literal","value":null}},{"op":"if","when":{"op":"path","from":"hasEvidence","path":""},"then":{"op":"format","template":"redacted {value}","values":{"value":{"op":"path","from":"evidence","path":"redactionVerified"}}},"else":{"op":"literal","value":null}},{"op":"if","when":{"op":"path","from":"hasEvidence","path":""},"then":{"op":"format","template":"http {value}","values":{"value":{"op":"path","from":"evidence","path":"httpStatus"}}},"else":{"op":"literal","value":null}}]},"else":{"op":"array","items":[]}}},"value":{"op":"object","fields":{"portId":{"op":"path","from":"operation","path":"portId"},"providerCellId":{"op":"path","from":"providerCell","path":"cellId"},"physicalCellId":{"op":"path","from":"physicalCell","path":"cellId"},"facts":{"op":"path","from":"facts","path":""}}}}},"responsibilities":{"op":"map","from":{"op":"path","from":"operations","path":""},"as":"operation","value":{"op":"let","bindings":{"cell":{"op":"find","from":{"op":"path","from":"cells","path":""},"as":"candidate","where":{"op":"equals","left":{"op":"path","from":"candidate","path":"execution.configuration.portId"},"right":{"op":"path","from":"operation","path":"portId"}}},"observed":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact","where":{"op":"equals","left":{"op":"path","from":"fact","path":"cellId"},"right":{"op":"path","from":"cell","path":"cellId"}}},"exchange":{"op":"find","from":{"op":"path","from":"exchangeEntries","path":""},"as":"exchangeEntry","where":{"op":"equals","left":{"op":"path","from":"exchangeEntry","path":"portId"},"right":{"op":"path","from":"operation","path":"portId"}}},"matchedFacts":{"op":"path","from":"exchange","path":"facts"}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"if","when":{"op":"path","from":"exchangeNotCompleted","path":""},"then":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"operation","path":"portId"},"right":{"op":"literal","value":"observe-equity-price-exchange"}},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"completed"}},"else":{"op":"literal","value":"completed"}},"else":{"op":"if","when":{"op":"path","from":"observed","path":""},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"format","template":"{responsibility}","values":{"responsibility":{"op":"path","from":"operation","path":"portId"}}},"note":{"op":"if","when":{"op":"path","from":"matchedFacts","path":""},"then":{"op":"join","value":{"op":"filter","from":{"op":"path","from":"matchedFacts","path":""},"as":"fact","where":{"op":"path","from":"fact","path":""}},"separator":" | "},"else":{"op":"literal","value":null}},"timing":{"op":"if","when":{"op":"path","from":"observed","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}}}}}},"roots":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"root","where":{"op":"equals","left":{"op":"path","from":"root","path":"parentCellId"},"right":{"op":"literal","value":null}}},"treeEntries":{"op":"map","from":{"op":"path","from":"roots","path":""},"as":"root","value":{"op":"let","bindings":{"observed3":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact3","where":{"op":"equals","left":{"op":"path","from":"fact3","path":"cellId"},"right":{"op":"path","from":"root","path":"cellId"}}},"children3":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"childCell3","where":{"op":"equals","left":{"op":"path","from":"childCell3","path":"parentCellId"},"right":{"op":"path","from":"root","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed3","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed3","path":""},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"root","path":"semanticAddress"},"timing":{"op":"if","when":{"op":"path","from":"observed3","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed3","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}},"children":{"op":"map","from":{"op":"path","from":"children3","path":""},"as":"child3","value":{"op":"let","bindings":{"observed2":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact2","where":{"op":"equals","left":{"op":"path","from":"fact2","path":"cellId"},"right":{"op":"path","from":"child3","path":"cellId"}}},"children2":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"childCell2","where":{"op":"equals","left":{"op":"path","from":"childCell2","path":"parentCellId"},"right":{"op":"path","from":"child3","path":"cellId"}}},"exchange3":{"op":"find","from":{"op":"path","from":"exchangeEntries","path":""},"as":"exchangeMatch3","where":{"op":"equals","left":{"op":"path","from":"exchangeMatch3","path":"portId"},"right":{"op":"path","from":"child3","path":"execution.configuration.portId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed2","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed2","path":""},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"child3","path":"semanticAddress"},"note":{"op":"if","when":{"op":"path","from":"exchange3","path":"facts"},"then":{"op":"join","value":{"op":"filter","from":{"op":"path","from":"exchange3","path":"facts"},"as":"fact","where":{"op":"path","from":"fact","path":""}},"separator":" | "},"else":{"op":"literal","value":null}},"timing":{"op":"if","when":{"op":"path","from":"observed2","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed2","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}},"children":{"op":"map","from":{"op":"path","from":"children2","path":""},"as":"child2","value":{"op":"let","bindings":{"observed1":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact1","where":{"op":"equals","left":{"op":"path","from":"fact1","path":"cellId"},"right":{"op":"path","from":"child2","path":"cellId"}}},"children1":{"op":"filter","from":{"op":"path","from":"cells","path":""},"as":"childCell1","where":{"op":"equals","left":{"op":"path","from":"childCell1","path":"parentCellId"},"right":{"op":"path","from":"child2","path":"cellId"}}},"exchange2":{"op":"find","from":{"op":"path","from":"exchangeEntries","path":""},"as":"exchangeMatch2","where":{"op":"equals","left":{"op":"path","from":"exchangeMatch2","path":"providerCellId"},"right":{"op":"path","from":"child2","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed1","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed1","path":""},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"child2","path":"semanticAddress"},"note":{"op":"if","when":{"op":"path","from":"exchange2","path":"facts"},"then":{"op":"join","value":{"op":"filter","from":{"op":"path","from":"exchange2","path":"facts"},"as":"fact","where":{"op":"path","from":"fact","path":""}},"separator":" | "},"else":{"op":"literal","value":null}},"timing":{"op":"if","when":{"op":"path","from":"observed1","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed1","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}},"children":{"op":"map","from":{"op":"path","from":"children1","path":""},"as":"child1","value":{"op":"let","bindings":{"observed0":{"op":"find","from":{"op":"path","from":"testimony","path":""},"as":"fact0","where":{"op":"equals","left":{"op":"path","from":"fact0","path":"cellId"},"right":{"op":"path","from":"child1","path":"cellId"}}},"exchange1":{"op":"find","from":{"op":"path","from":"exchangeEntries","path":""},"as":"exchangeMatch1","where":{"op":"equals","left":{"op":"path","from":"exchangeMatch1","path":"physicalCellId"},"right":{"op":"path","from":"child1","path":"cellId"}}}},"value":{"op":"object","fields":{"status":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"observed0","path":"disposition"},"right":{"op":"literal","value":"completed"}},"then":{"op":"literal","value":"completed"},"else":{"op":"if","when":{"op":"path","from":"observed0","path":""},"then":{"op":"literal","value":"failed"},"else":{"op":"literal","value":"unobserved"}}},"text":{"op":"path","from":"child1","path":"semanticAddress"},"note":{"op":"if","when":{"op":"path","from":"exchange1","path":"facts"},"then":{"op":"join","value":{"op":"filter","from":{"op":"path","from":"exchange1","path":"facts"},"as":"fact","where":{"op":"path","from":"fact","path":""}},"separator":" | "},"else":{"op":"literal","value":null}},"timing":{"op":"if","when":{"op":"path","from":"observed0","path":"durationMilliseconds"},"then":{"op":"format","template":"{duration} ms","values":{"duration":{"op":"path","from":"observed0","path":"durationMilliseconds"}}},"else":{"op":"literal","value":null}}}}}}}}}}}}}}}}}},"blocks":{"op":"filter","from":{"op":"array","items":[{"op":"object","fields":{"type":{"op":"literal","value":"heading"},"text":{"op":"format","template":"Scenario {scenarioId}","values":{"scenarioId":{"op":"path","from":"scenario","path":"scenarioId"}}}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"GIVEN"},"value":{"op":"path","from":"scenario","path":"input.inputId"},"note":{"op":"path","from":"scenario","path":"input.contract.contractId"}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"WHEN"},"entries":{"op":"path","from":"responsibilities","path":""}}},{"op":"object","fields":{"type":{"op":"literal","value":"lane"},"label":{"op":"literal","value":"THEN"},"entries":{"op":"array","items":[{"op":"object","fields":{"status":{"op":"path","from":"outcomeStatus","path":""},"text":{"op":"path","from":"scenario","path":"outcome.outcomeId"},"note":{"op":"path","from":"scenario","path":"outcome.contract.contractId"}}}]}}},{"op":"object","fields":{"type":{"op":"literal","value":"field"},"label":{"op":"literal","value":"STATUS"},"value":{"op":"path","from":"domainOutcome","path":"disposition"},"note":{"op":"path","from":"domainOutcome","path":"reasonCode"}}},{"op":"object","fields":{"type":{"op":"if","when":{"op":"path","from":"payload","path":""},"then":{"op":"literal","value":"display"},"else":{"op":"literal","value":null}},"as":{"op":"literal","value":"json"},"value":{"op":"path","from":"payload","path":""}}},{"op":"object","fields":{"type":{"op":"if","when":{"op":"equals","left":{"op":"path","from":"reading","path":""},"right":{"op":"literal","value":"trace"}},"then":{"op":"literal","value":"tree"},"else":{"op":"literal","value":null}},"label":{"op":"literal","value":"TRACE"},"entries":{"op":"path","from":"treeEntries","path":""}}}]},"as":"block","where":{"op":"path","from":"block","path":"type"}}},"value":{"op":"object","fields":{"documentType":{"op":"literal","value":"sfx-display-document.v1"},"blocks":{"op":"path","from":"blocks","path":""}}}}}';
DECLARE @transformation bigint, @version bigint;
EXEC model.put_semantic_definition 'TRANSFORMATION', @namespace, @transformationId, @semantics, @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
SET @transformation = (SELECT transformation_pk FROM model.transformation WHERE semantic_object_pk = @object);
IF @transformation IS NULL BEGIN
  INSERT model.transformation(namespace_pk, transformation_id, semantic_object_pk, object_kind)
  SELECT namespace_pk, @transformationId, @object, 'TRANSFORMATION' FROM model.semantic_object WHERE semantic_object_pk = @object;
  SET @transformation = SCOPE_IDENTITY();
END;
SET @version = (SELECT transformation_version_pk FROM model.transformation_version WHERE semantic_object_definition_pk = @definition);
IF @version IS NULL BEGIN
  INSERT model.transformation_version(transformation_pk, semantic_object_pk, semantic_object_definition_pk, definition_digest, expression_profile, object_kind, _owner_definition_pk, _canonical_pointer)
  VALUES(@transformation, @object, @definition, @digest, 'json-expression-tree.v1', 'TRANSFORMATION', @definition, N'');
  SET @version = SCOPE_IDENTITY();
  EXEC model.normalize_transformation_expression @version;
END

-- ============================== PROOF ==============================
-- 1. The declared provider identity, read back from the newest port definitions.
SELECT '1_provider_authorities' AS result_set, d.declared_id AS port_id,
 JSON_QUERY(d.definition_json, '$.semantics.configuration.providerAuthorities') AS provider_authorities,
 JSON_QUERY(d.definition_json, '$.semantics.configuration.endpointAuthorities[0].urlPrefixes') AS endpoint_prefixes
FROM analysis.v_selected_semantic_definition d
WHERE d.object_kind='PORT'
 AND d.namespace_id=@namespace
 AND d.declared_id IN (N'observe-equity-price-exchange', N'observe-fallback-price-exchange')
ORDER BY d.declared_id;

-- 2. The re-declared display transformation and the fact vocabulary it renders.
SELECT '2_display_transformation' AS result_set, t.transformation_id, @version AS transformation_version_pk,
 'sha256:'+LOWER(CONVERT(varchar(64), @digest, 2)) AS definition_digest,
 CONVERT(bit, CASE WHEN CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) LIKE N'%providerAuthorities%' THEN 1 ELSE 0 END) AS renders_provider_identity,
 CONVERT(bit, CASE WHEN CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) LIKE N'%httpStatus%' THEN 1 ELSE 0 END) AS renders_http_status,
 CONVERT(bit, CASE WHEN CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) LIKE N'%reachedStage%' THEN 1 ELSE 0 END) AS renders_reached_stage,
 CONVERT(bit, CASE WHEN CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) LIKE N'%transportDisposition%' THEN 1 ELSE 0 END) AS renders_transport_disposition,
 CONVERT(bit, CASE WHEN CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) LIKE N'%redactionVerified%' THEN 1 ELSE 0 END) AS renders_redaction_verified
FROM model.transformation t
JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk=@definition
JOIN source.content_object co ON co.content_object_pk=d.canonical_content_pk
WHERE t.semantic_object_pk=@object;

-- 3. The assembled graph source from the uncommitted transaction: the interface
--    port bindings carry the declared identity and the interface still names the
--    display transformation.
DECLARE @graph nvarchar(max)=(SELECT graph_source FROM analysis.capability_graph_source(N'resolve-equity-market-price-evidence',0,N'sidefx:capabilities'));
SELECT '3_graph_source' AS result_set,
 JSON_VALUE(b.value, '$.configuration.providerAuthorities[0].providerId') AS provider_id,
 JSON_QUERY(b.value, '$.configuration.providerAuthorities') AS provider_authorities
FROM OPENJSON(JSON_QUERY(@graph, '$.interfaceAuthority.portBindings')) b
WHERE JSON_VALUE(b.value, '$.portId') IN (N'observe-equity-price-exchange', N'observe-fallback-price-exchange')
ORDER BY JSON_VALUE(b.value, '$.portId');

SELECT '4_interface' AS result_set,
 JSON_VALUE(JSON_QUERY(@graph, '$.interfaceAuthority.interfaces[0].configuration'), '$.display.transformationId') AS display_transformation_id,
 (SELECT COUNT(*) FROM OPENJSON(JSON_QUERY(@graph, '$.semanticTransformations')) t
  WHERE JSON_VALUE(t.value, '$.id')=@transformationId) AS display_transformation_present;

-- 4. The write is proven by the readback: the selected definition is this one.
SELECT '5_selected_definition' AS result_set, d.declared_id,
 'sha256:'+LOWER(CONVERT(varchar(64), d.definition_digest, 2)) AS selected_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.object_kind='TRANSFORMATION' AND d.namespace_id=@namespace AND d.declared_id=@transformationId;

COMMIT TRANSACTION;
-- Installed 2026-09-19: providerAuthorities on the two exchange port bindings and the
-- re-declared observe display transformation rendering declared provider facts.
-- The dry run and the from-transaction display preflight both printed the provider,
-- binding, endpoint, exchange, reason, stage, calls, transport, redaction and http
-- facts for both routes; a replay selects the same content-addressed definitions.
