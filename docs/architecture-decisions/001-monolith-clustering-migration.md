# ADR-001: Migration from Microservices to Monolith + LibCluster Architecture

**Status**: Proposed  
**Date**: 2025-07-10  
**Authors**: Development Team  
**Reviewers**: Architecture Team

## Context

The TNT Pipeline ETL system currently uses a microservices architecture with separate applications:

- `file_scanner`: Discovers files in S3 and enqueues jobs (minimal processing)
- `etl_pipeline`: Processes ETL jobs from Oban queues (heavy processing)

Each service runs separate Oban instances controlled by the `APP_TYPE` environment variable, with different queue configurations and deployment models.

## Problem Statement

The current microservices approach has several operational and architectural challenges:

### Operational Complexity

1. **Multiple ECS Services**: Managing separate task definitions, services, and scaling policies
2. **Infrastructure Overhead**: Duplicate monitoring, logging, and deployment infrastructure
3. **Coordination Difficulty**: Limited communication between file discovery and processing components
4. **Resource Inefficiency**: File scanner tasks are lightweight but require full infrastructure setup

### Technical Limitations

1. **Scaling Granularity**: Cannot easily balance workload between file discovery and processing
2. **Job Coordination**: No direct mechanism for coordinating work between services
3. **Shared State**: Difficult to share caches, metrics, or coordination state
4. **Connection Pooling**: Multiple database connection pools for related functionality

### Cost and Maintenance

1. **Infrastructure Costs**: Separate ECS services, load balancers, and monitoring
2. **Development Overhead**: Multiple deployment pipelines and testing strategies
3. **Monitoring Complexity**: Distributed tracing across separate services

## Decision

We will migrate from the current microservices architecture to a **Unified Monolith with LibCluster** approach that provides:

1. **Single Application**: Unified codebase with role-based behavior using `NODE_ROLE` environment variable
2. **Shared Oban Instance**: Single Oban configuration with multiple queues for different job types
3. **LibCluster Integration**: Automatic node discovery and horizontal scaling capabilities
4. **Dynamic Role Assignment**: Nodes can specialize (file_scanner, etl_worker, balanced) while sharing workload

## Proposed Architecture

### Application Structure

```
TNT Pipeline Unified App
├── Node Role: file_scanner (S3 discovery: file_discovery queue)
├── Node Role: etl_worker (processing: etl_files, persist_results, dashboard_updates)
├── Node Role: balanced (mixed workload: all queues with load balancing)
└── Shared Oban Instance (cluster-aware with 5-queue architecture)
```

### Queue Configuration

```elixir
# Single Oban instance with role-based queues
{Oban, [
  name: TntPipeline.Oban,
  repo: Common.Repo,
  plugins: [Oban.Plugins.Pruner, Oban.Plugins.Gossip],
  queues: configure_queues_by_role()
]}

# Queue Architecture (5 queues)
# file_discovery: S3 scanning and file detection jobs
# etl_files: Main ETL processing pipeline  
# persist_results: DynamoDB batch write operations
# dashboard_updates: Real-time Phoenix LiveView updates
# monitoring: Health checks and system metrics
```

### Infrastructure Design

- **ECS Service**: Single service with multiple task definitions for different roles
- **Service Discovery**: AWS Cloud Map for automatic node discovery
- **Load Balancing**: Automatic job distribution across cluster nodes
- **Scaling**: Role-specific auto-scaling based on queue depth and resource utilization

## Alternatives Considered

### Alternative 1: Keep Current Microservices

**Pros**: Familiar architecture, proven in production, clear separation
**Cons**: Operational complexity, limited coordination, infrastructure overhead
**Decision**: Rejected due to operational burden and scaling limitations

### Alternative 2: Pure Microservices with Enhanced Communication

**Pros**: Maintains service boundaries, adds communication mechanisms
**Cons**: Increases complexity without addressing core issues, network overhead
**Decision**: Rejected as it compounds existing problems

### Alternative 3: Event-Driven Architecture

**Pros**: Loose coupling, scalable event processing
**Cons**: Additional infrastructure (message queues), eventual consistency complexity
**Decision**: Rejected as overkill for current requirements

### Alternative 4: Kubernetes with Pod Communication

**Pros**: Container orchestration, advanced networking
**Cons**: Kubernetes complexity, migration from ECS, operational overhead
**Decision**: Rejected to maintain ECS investment and simplicity

## Implementation Strategy

### Phase 1: Preparation (Week 1)

- [ ] Add LibCluster dependency to project
- [ ] Create unified application structure preserving current functionality
- [ ] Implement node role detection and configuration system
- [ ] Add service discovery infrastructure to ECS setup

### Phase 2: Parallel Deployment (Week 2)

- [ ] Deploy unified application alongside current microservices
- [ ] Test clustering functionality in staging environment
- [ ] Validate job processing and distribution across nodes
- [ ] Performance benchmarking against current architecture

### Phase 3: Migration (Week 3)

- [ ] Gradual traffic shifting to unified application (10%, 50%, 100%)
- [ ] Monitor cluster health, job processing rates, and error rates
- [ ] Validate scaling behavior under production load
- [ ] Document operational procedures for new architecture

### Phase 4: Cleanup (Week 4)

- [ ] Deprecate old microservices infrastructure
- [ ] Clean up unused ECS services and task definitions
- [ ] Update monitoring, alerting, and documentation
- [ ] Conduct retrospective and optimization review

## Expected Benefits

### Operational Benefits

1. **Simplified Deployment**: Single application with multiple deployment modes
2. **Unified Monitoring**: Single application metrics and logging pipeline
3. **Better Resource Utilization**: Dynamic workload distribution across nodes
4. **Cost Reduction**: Reduced infrastructure overhead and management complexity

### Technical Benefits

1. **Horizontal Scaling**: True elastic scaling based on workload demands
2. **Job Coordination**: Direct communication and coordination between components
3. **Shared State**: Cluster-wide caches, metrics, and coordination mechanisms
4. **Fault Tolerance**: Automatic job redistribution on node failures

### Development Benefits

1. **Single Codebase**: Unified development, testing, and deployment workflow
2. **Better Observability**: End-to-end tracing and monitoring within single application
3. **Simplified Testing**: Integrated testing without service boundary complications
4. **Enhanced Debugging**: Centralized logging and error handling

## Risks and Mitigations

### Risk 1: Increased Application Complexity

**Impact**: Medium  
**Probability**: Medium  
**Mitigation**:

- Comprehensive testing of clustering functionality
- Gradual rollout with fallback to current architecture
- Extensive documentation and team training

### Risk 2: Network Dependencies

**Impact**: High  
**Probability**: Low  
**Mitigation**:

- Robust health checking and monitoring
- Service discovery redundancy
- Network partition handling and recovery procedures

### Risk 3: Larger Blast Radius

**Impact**: High  
**Probability**: Low  
**Mitigation**:

- Comprehensive testing and staging validation
- Circuit breakers and error isolation
- Rollback procedures and monitoring

### Risk 4: Learning Curve

**Impact**: Medium  
**Probability**: Medium  
**Mitigation**:

- Team training on LibCluster and distributed systems
- Documentation and runbooks
- Gradual migration with knowledge transfer

## Success Metrics

### Performance Metrics

- **Job Processing Rate**: ≥ current throughput (baseline: X jobs/minute)
- **Latency**: Job completion time within 10% of current performance
- **Resource Utilization**: ≥ 20% improvement in CPU/memory efficiency
- **Scaling Time**: Node addition/removal within 5 minutes

### Reliability Metrics

- **Uptime**: ≥ 99.9% availability (same as current)
- **Error Rate**: ≤ current error rate (baseline: X%)
- **Recovery Time**: Node failure recovery within 2 minutes
- **Data Consistency**: Zero job loss during normal operations

### Operational Metrics

- **Deployment Time**: 50% reduction in deployment duration
- **Monitoring Complexity**: Single dashboard for end-to-end pipeline
- **Infrastructure Costs**: 15-25% reduction in ECS and monitoring costs
- **Development Velocity**: Faster feature development and debugging

## Rollback Plan

### Immediate Rollback (< 1 hour)

1. **Traffic Redirection**: Route new jobs back to existing microservices
2. **Job Completion**: Allow in-flight jobs to complete on new system
3. **Health Validation**: Ensure existing services are healthy and processing
4. **Data Consistency**: Verify no job duplication or loss during transition

### Gradual Rollback (1-24 hours)

1. **Percentage Reduction**: Gradually decrease traffic to new system (90%, 50%, 10%, 0%)
2. **Issue Analysis**: Identify and document specific problems encountered
3. **Performance Comparison**: Compare metrics between old and new systems
4. **Decision Point**: Determine whether to fix issues or complete rollback

### Complete Rollback (24-48 hours)

1. **Infrastructure Cleanup**: Remove new clustering infrastructure
2. **Configuration Reset**: Restore original microservices configuration
3. **Monitoring Reset**: Revert to original monitoring and alerting setup
4. **Documentation**: Document lessons learned and issues encountered

## Timeline

| Phase                        | Duration | Key Deliverables                                                    |
| ---------------------------- | -------- | ------------------------------------------------------------------- |
| Phase 1: Preparation         | 1 week   | Unified app structure, LibCluster integration, infrastructure setup |
| Phase 2: Parallel Deployment | 1 week   | Staging deployment, testing, performance benchmarking               |
| Phase 3: Migration           | 1 week   | Production rollout, traffic shifting, monitoring                    |
| Phase 4: Cleanup             | 1 week   | Infrastructure cleanup, documentation, optimization                 |

**Total Duration**: 4 weeks  
**Go/No-Go Decision Point**: End of Phase 2 based on performance and stability metrics

## Dependencies

### Technical Dependencies

- [ ] LibCluster library integration and testing
- [ ] ECS service discovery configuration
- [ ] Security group updates for inter-node communication
- [ ] Monitoring and alerting system updates

### Team Dependencies

- [ ] DevOps team for infrastructure changes
- [ ] QA team for comprehensive testing strategy
- [ ] Product team for traffic shifting approval
- [ ] Architecture team for design review and approval

### External Dependencies

- [ ] AWS service discovery service availability
- [ ] ECS platform stability during migration
- [ ] Database performance under new connection patterns
- [ ] Network infrastructure capacity for inter-node communication

## Conclusion

The migration to a unified monolith with LibCluster architecture addresses the operational complexity and scaling limitations of the current microservices approach while maintaining the benefits of horizontal scaling and fault tolerance.

This decision balances the need for operational simplicity with the requirement for scalable, distributed processing. The phased implementation approach minimizes risk while providing clear success criteria and rollback procedures.

The expected benefits in terms of cost reduction, operational simplicity, and development velocity justify the migration effort and associated risks.

---

**Next Steps**:

1. Architecture team review and approval
2. Detailed implementation planning for Phase 1
3. Team training on LibCluster and distributed systems concepts
4. Infrastructure change requests and approval process

