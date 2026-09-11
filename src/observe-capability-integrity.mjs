// Observations about what the selected model declares for one capability.
//
// Each observation is a fact read from the estate: a count, an absence, or a
// disagreement between two declarations. None of them is a judgement about
// whether the estate is correct — this module does not know what correct is, and
// never guesses an intent behind a gap. It puts the declared state where a
// reviewer can see it in one pass, and leaves the judgement to the reviewer.
//
// Observations are ordered structural first (the circuit does not join up),
// then divergence (two declarations disagree), then meaning (the authority
// declares no meaning at a point that carries meaning elsewhere).
const STRUCTURE = 'structure';
const DIVERGENCE = 'divergence';
const MEANING = 'meaning';
const order = { [STRUCTURE]: 0, [DIVERGENCE]: 1, [MEANING]: 2 };

const plural = (count, one, many) => `${count} ${count === 1 ? one : many}`;

export function observeCapabilityIntegrity(meaning) {
  const { capability, scenarios, executionAuthorities, ports, transformations,
    observableConditions, invocations, implementations, platformCapabilityUsage = [], features = [] } = meaning;
  const observations = [];
  const see = (kind, code, subject, statement) => observations.push({ kind, code, subject, statement });

  const inClosure = new Set(scenarios.map(scenario => scenario.scenarioId));
  const portsById = new Map(ports.map(port => [port.portId, port]));
  const owners = new Set(executionAuthorities.flatMap(authority =>
    authority.definitions.map(definition => definition.owningScenarioId).filter(Boolean)));

  // Structure: does the declared circuit actually join up?
  for (const scenario of scenarios) {
    if (!scenario.definitions.length) {
      see(STRUCTURE, 'SCENARIO_DEFINITION_ABSENT', scenario.scenarioId,
        'Named by the declared closure, but the model retains no definition for it.');
    }
    if (!owners.has(scenario.scenarioId)) {
      see(STRUCTURE, 'SCENARIO_WITHOUT_EXECUTION_AUTHORITY', scenario.scenarioId,
        'In the closure, but no execution authority declares it as the scenario it owns, so the circuit declares nothing to execute for it.');
    }
    if (scenario.cycleDetected) {
      see(STRUCTURE, 'CYCLE_DECLARED', scenario.scenarioId, 'The declared invocation closure reports a cycle reaching this scenario.');
    }
  }

  const reached = new Set([capability.selectedScenarioId]);
  for (let added = true; added;) {
    added = false;
    for (const edge of invocations) {
      if (reached.has(edge.fromScenarioId) && !reached.has(edge.toScenarioId)) { reached.add(edge.toScenarioId); added = true; }
    }
  }
  for (const scenario of scenarios) {
    if (!reached.has(scenario.scenarioId)) {
      see(STRUCTURE, 'SCENARIO_UNREACHED', scenario.scenarioId,
        'In the declared closure, but no declared invocation edge reaches it from the scenario read.');
    }
  }

  const referenced = new Set();
  const unresolvedInvocations = new Map();
  for (const authority of executionAuthorities) {
    for (const definition of authority.definitions) {
      const seen = new Set();
      for (const operation of definition.operations ?? []) {
        if (operation.portId) referenced.add(operation.portId);
        if (operation.kind === 'invoke-scenario' && operation.scenarioId && !inClosure.has(operation.scenarioId)) {
          // One fact per authority and target, carrying how many of that
          // authority's definitions declare it. Not one line per definition.
          const key = `${authority.authorityId} -> ${operation.scenarioId}`;
          if (!seen.has(key)) {
            seen.add(key);
            const entry = unresolvedInvocations.get(key) ?? { count: 0, total: authority.definitions.length };
            entry.count += 1;
            unresolvedInvocations.set(key, entry);
          }
        }
        if (!operation.kind) {
          see(STRUCTURE, 'OPERATION_KIND_ABSENT', authority.authorityId, 'An operation is declared with no kind.');
        }
      }
      if (!(definition.operations ?? []).length) {
        see(STRUCTURE, 'EXECUTION_AUTHORITY_WITHOUT_OPERATIONS', authority.authorityId,
          'A retained definition of this authority declares no operation, so it declares no execution.');
      }
    }
  }
  for (const [subject, { count, total }] of unresolvedInvocations) {
    const share = total > 1 ? ` Declared by ${count} of its ${total} retained definitions.` : '';
    see(STRUCTURE, 'SCENARIO_INVOCATION_UNRESOLVED', subject,
      `The authority declares an invocation of this scenario, but the model does not resolve it into the closure. Both are retained authority and they disagree.${share}`);
  }
  for (const portId of referenced) {
    if (!portsById.has(portId)) {
      see(STRUCTURE, 'PORT_DEFINITION_ABSENT', portId, 'An operation invokes this port, but the model retains no port definition for it.');
    }
  }
  // A port carrying no transformation is only worth a reviewer's attention when
  // the same platform capability is configured with one elsewhere in the estate.
  // Many platform capabilities take no transformation at all, and reporting
  // those would bury the real exceptions in noise.
  const usage = new Map(platformCapabilityUsage.map(item => [item.platformCapabilityId, item]));
  for (const port of ports) {
    if (!port.definitions.some(definition => definition.transformationId)) {
      for (const platform of new Set(port.definitions.map(definition => definition.platformCapabilityId).filter(Boolean))) {
        const item = usage.get(platform);
        if (!item || item.withTransformation === 0) continue;
        see(STRUCTURE, 'PORT_WITHOUT_TRANSFORMATION', port.portId,
          `The port declares no transformation, while ${item.withTransformation} of the ${item.portCount} ports the estate declares on \`${platform}\` do. The circuit declares no expression for what this one does.`);
      }
    }
    if (!port.definitions.some(definition => definition.platformCapabilityId)) {
      see(STRUCTURE, 'PORT_WITHOUT_PLATFORM_CAPABILITY', port.portId,
        'The port declares no platform capability, so no provider can be resolved for it.');
    }
  }

  // The mechanics end of the circuit: a platform capability nothing implements,
  // and a provider standing in the circuit with no mechanic behind it.
  const platforms = new Set(ports.flatMap(port =>
    port.definitions.map(definition => definition.platformCapabilityId).filter(Boolean)));
  const implemented = new Set(implementations.map(item => item.platformCapabilityId));
  for (const platform of [...platforms].sort()) {
    if (!implemented.has(platform)) {
      see(STRUCTURE, 'PLATFORM_CAPABILITY_WITHOUT_PROVIDER', platform,
        'A port declares this platform capability, but no provider in the selected model declares an implementation of it.');
    }
  }
  for (const providerId of [...new Set(implementations.map(item => item.providerId))].sort()) {
    const declared = implementations.filter(item => item.providerId === providerId);
    if (!declared.some(item => item.mechanicId !== null)) {
      see(MEANING, 'PROVIDER_WITHOUT_MECHANIC', providerId,
        'The provider declares an implementation of this circuit\'s platform capability, but declares no mechanic, so the circuit reaches it with no declared mechanism behind it.');
    }
  }

  // Divergence: one declared id, several retained definitions that disagree.
  const diverging = [
    ['EXECUTION_AUTHORITY', executionAuthorities, 'authorityId', definition => JSON.stringify(definition.operations ?? []), 'operation set'],
    ['PORT', ports, 'portId', definition => JSON.stringify([definition.platformCapabilityId, definition.transformationId]), 'binding'],
    ['SCENARIO', scenarios, 'scenarioId', definition => JSON.stringify([definition.specification, definition.face]), 'specification'],
    ['TRANSFORMATION', transformations, 'transformationId', definition => JSON.stringify(definition.expressionKeys ?? null), 'expression'],
  ];
  for (const [kind, items, key, shape, noun] of diverging) {
    for (const item of items) {
      if (item.definitions.length < 2) continue;
      const shapes = new Set(item.definitions.map(shape));
      see(DIVERGENCE, shapes.size > 1 ? `${kind}_DEFINITIONS_DISAGREE` : `${kind}_DEFINITIONS_REPEATED`, item[key],
        shapes.size > 1
          ? `${plural(item.definitions.length, 'retained definition', 'retained definitions')} declaring ${plural(shapes.size, `different ${noun}`, `different ${noun}s`)}. The circuit draws their union; no single definition declares all of it.`
          : `${plural(item.definitions.length, 'retained definition', 'retained definitions')} with differing digests that declare the same thing.`);
    }
  }

  // The canonical feature binding, as migrations 007/008 retain it.
  if (!features.length) {
    see(STRUCTURE, 'CANONICAL_FEATURE_UNBOUND', capability.capabilityId,
      'The estate binds no canonical feature to this capability.');
  } else {
    const canonical = features.filter(feature => feature.bindingRole === 'CANONICAL');
    if (!canonical.length) {
      see(STRUCTURE, 'CANONICAL_FEATURE_UNBOUND', capability.capabilityId,
        `A feature is retained for this capability, but no profile is bound CANONICAL in this generation (${features.map(f => f.sourceProfile).join(', ')}).`);
    }
    for (const feature of canonical) {
      if (feature.name || feature.description) continue;
      // The binding the generation selects carries no parsed declaration, while
      // another retained profile may. That is a fact about the binding.
      const carrier = features.find(other => other.name || other.description);
      see(MEANING, 'CANONICAL_FEATURE_DECLARATION_ABSENT', feature.featureId,
        carrier
          ? `The CANONICAL binding is \`${feature.sourceProfile}\`, which declares no feature name or narrative; the parsed declaration is retained on \`${carrier.sourceProfile}\`, which this generation does not bind canonically.`
          : 'The CANONICAL binding declares no feature name or narrative.');
    }
  }

  // Meaning: the authority declares none where meaning is otherwise carried.
  if (!capability.userStory) see(MEANING, 'USER_STORY_ABSENT', capability.capabilityId, 'The capability declares no user story, so it states no actor, intent or outcome.');
  if (!capability.experience) see(MEANING, 'EXPERIENCE_ABSENT', capability.capabilityId, 'The capability declares no experience, so it states no promise.');
  if (!observableConditions.length) see(MEANING, 'OBSERVABLE_CONDITIONS_ABSENT', capability.capabilityId, 'No observable condition is declared against this capability definition, so nothing states how its promise is observed.');
  for (const scenario of scenarios) {
    if (!scenario.definitions.length) continue;
    if (scenario.definitions.some(definition => definition.specification)) continue;
    see(MEANING, 'SCENARIO_SPECIFICATION_ABSENT', scenario.scenarioId,
      scenario.definitions.some(definition => definition.face)
        ? 'Every retained definition declares the scenario\'s face only. No definition declares an authored specification, so the scenario states no behaviour in language.'
        : 'No retained definition declares an authored specification or a face.');
  }
  for (const transformation of transformations) {
    if (transformation.definitions.some(definition => (definition.expressionKeys ?? []).length)) continue;
    see(MEANING, 'TRANSFORMATION_WITHOUT_EXPRESSION', transformation.transformationId,
      'The transformation declares no expression, so the circuit declares no computation for the port configured with it.');
  }

  return observations.sort((a, b) => order[a.kind] - order[b.kind]
    || a.code.localeCompare(b.code) || String(a.subject).localeCompare(String(b.subject)));
}

export const observationKinds = { STRUCTURE, DIVERGENCE, MEANING };
