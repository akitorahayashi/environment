use std::collections::{HashMap, HashSet};

use crate::error::AppError;
use crate::provisioning::execution_plan::ExecutionUnit;

fn selected_index_map(units: &[ExecutionUnit]) -> HashMap<String, usize> {
    units.iter().enumerate().map(|(index, unit)| (unit.name.clone(), index)).collect()
}

fn selected_names(units: &[ExecutionUnit]) -> HashSet<String> {
    units.iter().map(|unit| unit.name.clone()).collect()
}

fn build_graph(
    selected: &HashSet<String>,
    order_constraints: &HashMap<String, Vec<String>>,
) -> (HashMap<String, Vec<String>>, HashMap<String, usize>) {
    let mut dependents: HashMap<String, Vec<String>> = HashMap::new();
    let mut indegree: HashMap<String, usize> =
        selected.iter().map(|tag| (tag.clone(), 0)).collect();

    for (target, prerequisites) in order_constraints {
        if !selected.contains(target) {
            continue;
        }

        for prerequisite in prerequisites {
            if !selected.contains(prerequisite) {
                continue;
            }

            dependents.entry(prerequisite.clone()).or_default().push(target.clone());
            *indegree.entry(target.clone()).or_default() += 1;
        }
    }

    (dependents, indegree)
}

fn cycle_path(
    node: &str,
    dependents: &HashMap<String, Vec<String>>,
    visiting: &mut Vec<String>,
    visited: &mut HashSet<String>,
) -> Option<Vec<String>> {
    if let Some(position) = visiting.iter().position(|current| current == node) {
        let mut cycle = visiting[position..].to_vec();
        cycle.push(node.to_string());
        return Some(cycle);
    }

    if !visited.insert(node.to_string()) {
        return None;
    }

    visiting.push(node.to_string());
    if let Some(next_nodes) = dependents.get(node) {
        for next in next_nodes {
            if let Some(cycle) = cycle_path(next, dependents, visiting, visited) {
                return Some(cycle);
            }
        }
    }
    visiting.pop();
    None
}

fn detect_cycle(dependents: &HashMap<String, Vec<String>>) -> Option<Vec<String>> {
    let mut visited = HashSet::new();
    for node in dependents.keys() {
        let mut visiting = Vec::new();
        if let Some(cycle) = cycle_path(node, dependents, &mut visiting, &mut visited) {
            return Some(cycle);
        }
    }
    None
}

pub fn order_units(
    units: Vec<ExecutionUnit>,
    order_constraints: &HashMap<String, Vec<String>>,
) -> Result<Vec<ExecutionUnit>, AppError> {
    let index_map = selected_index_map(&units);
    let selected = selected_names(&units);
    let (dependents, mut indegree) = build_graph(&selected, order_constraints);

    let mut remaining: HashMap<String, ExecutionUnit> =
        units.into_iter().map(|unit| (unit.name.clone(), unit)).collect();
    let mut ordered = Vec::with_capacity(remaining.len());

    while !remaining.is_empty() {
        let mut ready: Vec<String> = indegree
            .iter()
            .filter_map(|(name, degree)| (*degree == 0).then_some(name.clone()))
            .collect();
        ready.sort_by_key(|name| index_map.get(name).copied().unwrap_or(usize::MAX));

        if ready.is_empty() {
            if let Some(cycle) = detect_cycle(&dependents) {
                return Err(AppError::InvalidExecutionOrder(format!(
                    "cycle detected: {}",
                    cycle.join(" -> ")
                )));
            }

            return Err(AppError::InvalidExecutionOrder(
                "no executable units remain after applying order constraints".to_string(),
            ));
        }

        for name in ready {
            if let Some(unit) = remaining.remove(&name) {
                ordered.push(unit);
                indegree.remove(&name);
                if let Some(dependent_names) = dependents.get(&name) {
                    for dependent in dependent_names {
                        if let Some(value) = indegree.get_mut(dependent) {
                            *value = value.saturating_sub(1);
                        }
                    }
                }
            }
        }
    }

    Ok(ordered)
}

pub fn layer_units(
    units: Vec<ExecutionUnit>,
    order_constraints: &HashMap<String, Vec<String>>,
) -> Result<Vec<Vec<ExecutionUnit>>, AppError> {
    let index_map = selected_index_map(&units);
    let selected = selected_names(&units);
    let (dependents, mut indegree) = build_graph(&selected, order_constraints);

    let mut remaining: HashMap<String, ExecutionUnit> =
        units.into_iter().map(|unit| (unit.name.clone(), unit)).collect();
    let mut layers = Vec::new();

    while !remaining.is_empty() {
        let mut ready: Vec<String> = indegree
            .iter()
            .filter_map(|(name, degree)| (*degree == 0).then_some(name.clone()))
            .collect();
        ready.sort_by_key(|name| index_map.get(name).copied().unwrap_or(usize::MAX));

        if ready.is_empty() {
            if let Some(cycle) = detect_cycle(&dependents) {
                return Err(AppError::InvalidExecutionOrder(format!(
                    "cycle detected: {}",
                    cycle.join(" -> ")
                )));
            }

            return Err(AppError::InvalidExecutionOrder(
                "no executable units remain after applying order constraints".to_string(),
            ));
        }

        let mut layer = Vec::with_capacity(ready.len());
        for name in ready {
            if let Some(unit) = remaining.remove(&name) {
                layer.push(unit);
                indegree.remove(&name);
                if let Some(dependent_names) = dependents.get(&name) {
                    for dependent in dependent_names {
                        if let Some(value) = indegree.get_mut(dependent) {
                            *value = value.saturating_sub(1);
                        }
                    }
                }
            }
        }
        layers.push(layer);
    }

    Ok(layers)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn unit(name: &str) -> ExecutionUnit {
        ExecutionUnit::atomic(name)
    }

    #[test]
    fn orders_selected_units() {
        let units = vec![unit("tools"), unit("platform")];
        let mut constraints = HashMap::new();
        constraints.insert("tools".to_string(), vec!["platform".to_string()]);

        let ordered = order_units(units, &constraints).unwrap();
        assert_eq!(
            ordered.into_iter().map(|unit| unit.name).collect::<Vec<_>>(),
            vec!["platform", "tools"]
        );
    }

    #[test]
    fn layers_selected_units() {
        let units = vec![unit("platform"), unit("tools"), unit("shell")];
        let mut constraints = HashMap::new();
        constraints.insert("tools".to_string(), vec!["platform".to_string()]);

        let layers = layer_units(units, &constraints).unwrap();
        assert_eq!(layers.len(), 2);
        assert_eq!(
            layers[0].iter().map(|unit| unit.name.clone()).collect::<Vec<_>>(),
            vec!["platform", "shell"]
        );
        assert_eq!(
            layers[1].iter().map(|unit| unit.name.clone()).collect::<Vec<_>>(),
            vec!["tools"]
        );
    }

    #[test]
    fn detects_cycles() {
        let units = vec![unit("platform"), unit("tools")];
        let mut constraints = HashMap::new();
        constraints.insert("platform".to_string(), vec!["tools".to_string()]);
        constraints.insert("tools".to_string(), vec!["platform".to_string()]);

        let result = order_units(units, &constraints);
        assert!(matches!(result, Err(AppError::InvalidExecutionOrder(_))));
    }
}
