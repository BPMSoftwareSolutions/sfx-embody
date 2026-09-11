// Render the capability's canonical story as review-ready Markdown.
//
// Same rule as the plain narrator: this composes headings, tables and diagram
// layout only. Every fact is a value read from the estate model. Absent
// authority is stated as absent and never replaced with plausible text.
//
// Two things this renderer deliberately refuses to smooth over, because both are
// real conditions of the selected model and both matter to a reviewer:
//
//   * one declared id may have several retained definitions, and they may
//     disagree. Every definition is shown as it is; none are merged into a union.
//   * an execution authority may declare an invocation of a scenario the model
//     does not resolve into the closure. That disagreement is reported.
//
// The invocation tree is drawn from the scenario invocations the model declares
// as relationships, never from an ordering guessed out of closure depth.
import { executionOrderDiagrams } from './diagram-capability-circuit.mjs';
import { observeCapabilityIntegrity, observationKinds } from './observe-capability-integrity.mjs';
import { blueprintDiagram, circuitFromAuthority, compareBlueprintToCircuit } from './diagram-blueprint-circuit.mjs';

const ABSENT = '_(not declared)_';
const PLAIN = '(not declared)';
const has = text => typeof text === 'string' && text.trim().length > 0;
const value = text => (has(text) ? text : ABSENT);
const plain = text => (has(text) ? text : PLAIN);
// Markdown table cells cannot carry a raw pipe or newline.
const cell = text => (has(text) ? text.replace(/\|/g, '\\|').replace(/\s*\n\s*/g, ' ') : ABSENT);
const fence = (lines, language = 'text') => ['```' + language, ...lines, '```'];
const short = digest => (typeof digest === 'string' ? digest.replace(/^sha256:/, '').slice(0, 12) : PLAIN);

function table(headers, rows) {
  if (!rows.length) return [];
  return [`| ${headers.join(' | ')} |`, `| ${headers.map(() => '---').join(' | ')} |`,
    ...rows.map(row => `| ${row.map(cell).join(' | ')} |`)];
}

function distinct(definitions, field) {
  return [...new Set(definitions.map(definition => definition[field]).filter(item => item !== null && item !== undefined))].sort();
}

// A real tree over declared edges. Repeated and cyclic targets are marked where
// they recur instead of being expanded again.
function invocationTree(rootId, scenarios, invocations) {
  const children = new Map();
  for (const edge of invocations) {
    if (!children.has(edge.fromScenarioId)) children.set(edge.fromScenarioId, []);
    children.get(edge.fromScenarioId).push(edge.toScenarioId);
  }
  for (const list of children.values()) list.sort();
  const lines = [];
  const expanded = new Set();
  const walk = (id, prefix, last, root) => {
    const seen = expanded.has(id);
    lines.push(root ? id : `${prefix}${last ? '`-- ' : '|-- '}${id}${seen ? '  (shown above)' : ''}`);
    if (seen) return;
    expanded.add(id);
    const kids = children.get(id) ?? [];
    const next = root ? '' : prefix + (last ? '    ' : '|   ');
    kids.forEach((kid, index) => walk(kid, next, index === kids.length - 1, false));
  };
  walk(rootId, '', true, true);
  return { lines, unreached: scenarios.map(scenario => scenario.scenarioId).filter(id => !expanded.has(id)) };
}

function operationSketch(definition, portsById, inClosure, unresolved) {
  const lines = [];
  if (!definition.operations.length) lines.push(`\`-- operations: ${PLAIN}`);
  definition.operations.forEach((operation, index) => {
    const last = index === definition.operations.length - 1;
    const target = operation.portId ?? operation.scenarioId ?? null;
    const missing = operation.kind === 'invoke-scenario' && operation.scenarioId && !inClosure.has(operation.scenarioId);
    if (missing && !unresolved.includes(operation.scenarioId)) unresolved.push(operation.scenarioId);
    lines.push(`${last ? '`--' : '|--'} ${index + 1}. ${plain(operation.kind)}${target ? ` --> ${target}` : ''}${missing ? '   (not in the declared closure)' : ''}`);
    const stem = last ? '    ' : '|   ';
    const port = operation.portId ? portsById.get(operation.portId) : undefined;
    if (operation.portId && !port) lines.push(`${stem}\`-- port definition: ${PLAIN}`);
    if (port) {
      lines.push(`${stem}|-- platform capability: ${distinct(port.definitions, 'platformCapabilityId').join(', ') || PLAIN}`);
      lines.push(`${stem}\`-- transformation: ${distinct(port.definitions, 'transformationId').join(', ') || PLAIN}`);
    }
  });
  return lines;
}

function scenarioSection(scenario, lines) {
  const specified = scenario.definitions.find(definition => definition.specification) ?? null;
  lines.push(`### ${specified?.specification.name ?? scenario.scenarioId}`, '');
  lines.push(...table(['Field', 'Value'], [
    ['Scenario', `\`${scenario.scenarioId}\``],
    ['Depth', scenario.minimumDepth === 0 ? '0 (the scenario read)' : String(scenario.minimumDepth)],
    ...(scenario.cycleDetected ? [['Cycle', 'declared']] : []),
    ['Retained definitions', String(scenario.definitions.length)],
  ]));
  lines.push('');
  if (!scenario.definitions.length) {
    lines.push('This scenario is named by the declared closure; the estate retains no definition for it.', '');
    return;
  }
  const labelled = scenario.definitions.length > 1;
  if (labelled) lines.push(`The model retains ${scenario.definitions.length} definitions for this scenario. Each is shown as retained.`, '');
  for (const definition of scenario.definitions) {
    if (labelled) lines.push(`**Definition \`${short(definition.definitionDigest)}\`**`, '');
    if (definition.specification) {
      const specification = definition.specification;
      if (specification.description) lines.push(specification.description, '');
      if (specification.steps.length) {
        // The steps are authored prose in the authority and are reproduced verbatim.
        lines.push(...fence([`${specification.keyword ?? 'Scenario'}: ${specification.name ?? scenario.scenarioId}`,
          ...specification.steps.map(step => `  ${(step.keyword ?? '').trim()} ${step.text ?? ''}`.trimEnd())], 'gherkin'), '');
      } else {
        lines.push(`Steps: ${ABSENT}`, '');
      }
      if (specification.tags.length) lines.push(`Tags: ${specification.tags.map(tag => `\`${tag}\``).join(', ')}`, '');
      if (specification.examples.length) lines.push(`Examples declared: ${specification.examples.length}`, '');
    } else if (definition.face) {
      // A face is a different declaration from an authored specification, not a
      // missing one, and is reported as what it is.
      lines.push('This definition declares the scenario\'s face rather than an authored specification.', '');
      lines.push(...table(['Face', 'Declared'], [
        ['Event', definition.face.event], ['Input', definition.face.input], ['Outcome', definition.face.outcome],
      ]), '');
    } else {
      lines.push(`This definition declares neither an authored specification nor a face. ${ABSENT}`, '');
    }
  }
}

export function narrateCapabilityMarkdown(meaning) {
  const { capability, scenarios, executionAuthorities, ports, transformations,
    observableConditions, invocations, mechanics, providers } = meaning;
  const lines = [];

  lines.push(`# ${capability.capabilityId}`, '');
  if (has(capability.userStory?.intent)) lines.push(`> ${capability.userStory.intent}`, '');

  lines.push('## Identity', '');
  lines.push(...table(['Field', 'Value'], [
    ['Capability', capability.capabilityId],
    ['Namespace', capability.namespaceId],
    ['Mode', capability.mode],
    ['Declared root scenario', capability.declaredRootCount === 1
      ? capability.declaredRootScenarioId : `(not declared: ${capability.declaredRootCount} declared root scenarios)`],
    ...(capability.selectedScenarioId === capability.declaredRootScenarioId
      ? [] : [['Scenario read', capability.selectedScenarioId]]),
    ['Definition digest', `\`${capability.definitionDigest}\``],
    ['Snapshot', `\`${meaning.snapshotId}\``],
    ['Projection', `\`${meaning.projectionDigest}\``],
  ]));
  lines.push('');

  // What a reviewer must see first: where the declared circuit does not join
  // up, where two declarations disagree, and where meaning is not declared.
  const observations = observeCapabilityIntegrity(meaning);
  lines.push(`## Review summary (${observations.length} ${observations.length === 1 ? 'observation' : 'observations'})`, '');
  if (!observations.length) {
    lines.push('Every declared id in this circuit resolves, no two retained definitions disagree,',
      'and meaning is declared at every point this report inspects.', '');
  } else {
    lines.push('Each line states what the selected model declares. None is a judgement about',
      "whether the estate is correct - that is the reviewer's to make.", '');
    for (const [kind, title] of [[observationKinds.STRUCTURE, 'Structure — the declared circuit does not join up here'],
      [observationKinds.DIVERGENCE, 'Divergence — one declared id, definitions that disagree'],
      [observationKinds.MEANING, 'Meaning — the authority declares none here']]) {
      const group = observations.filter(observation => observation.kind === kind);
      if (!group.length) continue;
      lines.push(`**${title} (${group.length})**`, '');
      lines.push(...table(['Subject', 'Observation', 'Code'],
        group.map(observation => [`\`${observation.subject}\``, observation.statement, `\`${observation.code}\``])), '');
    }
  }

  lines.push('## Capability circuit today', '');
  lines.push('The circuit the estate declares now, drawn in the same shape a blueprint is drawn in,',
    'so the two can be read against each other. Node shape is the declared kind, the label lines',
    'are the declared face, and each edge caption is the declared operation kind and its step in',
    'the declared order. A node in red is a point the review summary names.', '');
  lines.push(...fence(blueprintDiagram(circuitFromAuthority(meaning)), 'mermaid'), '');

  // What the circuit is today, beside what its blueprint candidate proposed.
  const blueprints = meaning.blueprints ?? [];
  lines.push(`## Blueprint candidate (${blueprints.length})`, '');
  if (!blueprints.length) {
    lines.push('The estate retains no circuit blueprint candidate bound to this capability,',
      "so there is nothing to compare today's circuit against.", '');
  }
  for (const blueprint of blueprints) {
    lines.push(`### \`${blueprint.blueprintId}\``, '');
    lines.push(...table(['Field', 'Value'], [
      ['Carrier', blueprint.carrierVersion],
      ['Blueprint version', blueprint.capability?.version],
      ['Root experience', blueprint.capability?.rootExperience],
      ['Definition digest', `\`${blueprint.definitionDigest}\``],
      ['Declared nodes', String(blueprint.nodes.length)],
      ['Declared edges', String(blueprint.edges.length)],
    ]), '');
    lines.push('Generated from the retained blueprint authority on every read, not from a',
      'pre-rendered artifact. Node shape is the declared kind; every edge caption is the',
      'declared selecting variant, topology, semantic progress and bounded return.', '');
    lines.push(...fence(blueprintDiagram(blueprint), 'mermaid'), '');

    const comparison = compareBlueprintToCircuit(blueprint, meaning);
    lines.push('#### Proposed against today', '');
    for (const [title, side, proposedLabel, todayLabel] of [
      ['Cells and scenarios', comparison.cells, "Proposed as a cell, no scenario of that name in today's closure", "In today's closure, not proposed as a cell"],
      ['Ports', comparison.ports, 'Proposed as a provider slot, not a port today', 'A port today, not proposed as a provider slot']]) {
      lines.push(`**${title}**`, '');
      // An empty side is none, not undeclared. The distinction matters here.
      const listed = items => (items.length ? items.map(item => `\`${item}\``).join(', ') : 'none');
      lines.push(...table(['Standing', 'Count', 'Declared'], [
        ['Proposed and present today', String(side.both.length), listed(side.both)],
        [proposedLabel, String(side.proposedOnly.length), listed(side.proposedOnly)],
        [todayLabel, String(side.todayOnly.length), listed(side.todayOnly)],
      ]), '');
    }
    lines.push('A name on one side only is reported as exactly that. Which side is right is the',
      "reviewer's to decide.", '');
  }

  const traces = executionOrderDiagrams(meaning);
  if (traces.length) {
    lines.push('## Execution order', '');
    lines.push(`The declared operation sequence for \`${capability.selectedScenarioId}\`, in the order the`,
      'execution authority declares it.', '');
    if (traces.length > 1) {
      lines.push(`Its definitions declare **${traces.length} different sequences**. Each is drawn as declared;`,
        "no single one of them is the capability's order.", '');
    }
    for (const trace of traces) {
      if (traces.length > 1 || trace.definitionCount > 1) {
        lines.push(`**\`${trace.authorityId}\` — ${trace.digests.length} of ${trace.definitionCount} definitions** (${trace.digests.map(digest => `\`${short(digest)}\``).join(', ')})`, '');
      }
      lines.push(...fence(trace.lines, 'mermaid'), '');
    }
  }

  const features = meaning.features ?? [];
  lines.push(`## Canonical feature (${features.length})`, '');
  if (!features.length) {
    lines.push(`The estate binds no canonical feature to this capability. ${ABSENT}`, '');
  } else {
    lines.push(...table(['Profile', 'Binding', 'Retained source', 'Source bytes', 'Pinned scenarios'],
      features.map(feature => [`\`${feature.sourceProfile}\``,
        [feature.bindingRole, feature.generationBound ? 'generation-scoped' : null].filter(Boolean).join(' + ') || 'not bound',
        `\`${feature.sourcePath}\``, `\`${feature.contentDigest}\``, String(feature.pinnedScenarios)])), '');
    for (const feature of features) {
      if (!feature.name && !feature.description) continue;
      if (feature.name) lines.push(`### ${feature.name}`, '');
      if (feature.description) {
        // The Feature narrative as the writeup states it.
        lines.push(...feature.description.split('\n').map(item => item.trim()).filter(Boolean), '');
      }
    }
  }

  lines.push('## User story', '');
  if (capability.userStory) {
    lines.push(...table(['Field', 'Declared'], [
      ['Actor', capability.userStory.actor],
      ['Intent', capability.userStory.intent],
      ['Outcome', capability.userStory.outcome],
    ]), '');
  } else {
    lines.push(`The estate declares no user story for this capability. ${ABSENT}`, '');
  }

  lines.push('## Experience', '');
  if (capability.experience) {
    lines.push(...table(['Field', 'Declared'], [
      ['Actor', capability.experience.actor],
      ['Experience', capability.experience.experienceId],
      ['Promise', capability.experience.promise],
    ]), '');
  } else {
    lines.push(`The estate declares no experience for this capability. ${ABSENT}`, '');
  }

  lines.push(`## Observable conditions (${observableConditions.length})`, '');
  if (observableConditions.length) {
    // The estate retains an identity for each condition and no prose, so the
    // identities are listed exactly as retained.
    for (const condition of observableConditions) lines.push(`- \`${condition.conditionId}\``);
  } else {
    lines.push(`No observable condition is declared against this capability definition. ${ABSENT}`);
  }
  lines.push('');

  lines.push(`## Scenario closure (${scenarios.length})`, '');
  const tree = invocationTree(capability.selectedScenarioId, scenarios, invocations);
  lines.push(`The model declares ${invocations.length} scenario ${invocations.length === 1 ? 'invocation' : 'invocations'} as relationships between these scenarios.`, '');
  if (tree.unreached.length) {
    lines.push(`${tree.unreached.length === 1 ? 'This scenario is' : 'These scenarios are'} in the declared closure, but no declared invocation edge reaches ${tree.unreached.length === 1 ? 'it' : 'them'} from the scenario read:`, '');
    for (const id of tree.unreached) lines.push(`- \`${id}\``);
    lines.push('');
  }

  lines.push('## Scenarios', '');
  for (const scenario of scenarios) scenarioSection(scenario, lines);

  lines.push(`## Execution plan (${executionAuthorities.length} declared execution ${executionAuthorities.length === 1 ? 'authority' : 'authorities'})`, '');
  if (!executionAuthorities.length) {
    lines.push(`No execution authority is declared for the scenarios in this closure. ${ABSENT}`, '');
  }
  const portsById = new Map(ports.map(port => [port.portId, port]));
  const inClosure = new Set(scenarios.map(scenario => scenario.scenarioId));
  const unresolved = [];
  for (const authority of executionAuthorities) {
    const shapes = new Set(authority.definitions.map(definition => JSON.stringify(definition.operations)));
    lines.push(`### \`${authority.authorityId}\``, '');
    lines.push(...table(['Field', 'Value'], [
      ['Owning scenario', distinct(authority.definitions, 'owningScenarioId').join(', ')],
      ['Retained definitions', String(authority.definitions.length)],
      ...(authority.definitions.length > 1
        ? [['Agreement', shapes.size === 1 ? 'all declare the same operations'
          : `**they declare ${shapes.size} different operation sets**`]] : []),
    ]));
    lines.push('');
    for (const definition of authority.definitions) {
      const head = authority.definitions.length === 1
        ? authority.authorityId : `${authority.authorityId}   (definition ${short(definition.definitionDigest)})`;
      lines.push(...fence([head, ...operationSketch(definition, portsById, inClosure, unresolved)]), '');
    }
  }

  if (unresolved.length) {
    lines.push(`## Declared scenario invocations not in the closure (${unresolved.length})`, '');
    lines.push('An execution authority declares an invocation of these scenarios, but the selected',
      'estate model does not resolve them into this capability\'s closure. Both statements are',
      'retained authority; they disagree.', '');
    for (const id of unresolved.sort()) lines.push(`- \`${id}\``);
    lines.push('');
  }

  lines.push(`## Transformations (${transformations.length})`, '');
  if (!transformations.length) {
    lines.push(`No transformation is configured by these ports. ${ABSENT}`, '');
  } else {
    lines.push(...table(['Transformation', 'Retained definitions', 'Declared expression keys'],
      transformations.map(transformation => [
        `\`${transformation.transformationId}\``,
        String(transformation.definitions.length),
        [...new Set(transformation.definitions.flatMap(definition => definition.expressionKeys ?? []))].sort().join(', '),
      ])), '');
  }

  lines.push(`## Mechanics (${mechanics.length})`, '');
  if (!mechanics.length) {
    lines.push(`No provider declares a mechanic implementation for these platform capabilities. ${ABSENT}`, '');
  } else {
    lines.push(`${providers.length} ${providers.length === 1 ? 'provider declares' : 'providers declare'} an implementation of these ports' platform capabilities.`, '');
    lines.push(...table(['Provider', 'Mechanic', 'Definition profile', 'Via platform capability'],
      mechanics.map(mechanic => [`\`${mechanic.providerId}\``, `\`${mechanic.mechanicId}\``,
        mechanic.definitionProfile, `\`${mechanic.platformCapabilityId}\``])), '');
  }

  lines.push('---', '');
  lines.push(`Read from snapshot \`${meaning.snapshotId}\`, projection \`${meaning.projectionDigest}\`.`);
  lines.push('Every value above is retained estate authority; nothing is inferred or supplied by the renderer.');
  return lines;
}
