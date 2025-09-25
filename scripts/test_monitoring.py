#!/usr/bin/env python3
"""
Monitoring system validation and testing script for Electra.
Tests all monitoring components and generates sample data.
"""
import argparse
import json
import random
import requests
import time
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List


class MonitoringTester:
    """Test suite for Electra monitoring system."""
    
    def __init__(self, base_url="http://localhost"):
        self.base_url = base_url
        self.prometheus_url = f"{base_url}:9090"
        self.grafana_url = f"{base_url}:3000"
        self.jaeger_url = f"{base_url}:16686"
        self.elasticsearch_url = f"{base_url}:9200"
        self.django_url = f"{base_url}:8000"
        
        self.test_results = []
    
    def test_service_health(self) -> Dict[str, bool]:
        """Test health of all monitoring services."""
        services = {
            "Prometheus": f"{self.prometheus_url}/-/healthy",
            "Grafana": f"{self.grafana_url}/api/health",
            "Jaeger": f"{self.jaeger_url}/",
            "Elasticsearch": f"{self.elasticsearch_url}/_cluster/health",
            "Django": f"{self.django_url}/api/health/",
            "Django Metrics": f"{self.django_url}/metrics",
        }
        
        results = {}
        print("🔍 Testing service health...")
        
        for service, url in services.items():
            try:
                response = requests.get(url, timeout=10)
                healthy = response.status_code == 200
                results[service] = healthy
                status = "✅" if healthy else "❌"
                print(f"  {status} {service}: {'Healthy' if healthy else 'Unhealthy'}")
            except Exception as e:
                results[service] = False
                print(f"  ❌ {service}: Error - {e}")
        
        return results
    
    def test_prometheus_targets(self) -> Dict[str, int]:
        """Test Prometheus target discovery."""
        print("\n🎯 Testing Prometheus targets...")
        
        try:
            response = requests.get(f"{self.prometheus_url}/api/v1/targets")
            data = response.json()
            
            if data['status'] == 'success':
                targets = data['data']['activeTargets']
                healthy_targets = [t for t in targets if t['health'] == 'up']
                
                print(f"  Total targets: {len(targets)}")
                print(f"  Healthy targets: {len(healthy_targets)}")
                
                for target in targets:
                    status = "✅" if target['health'] == 'up' else "❌"
                    job = target['labels']['job']
                    instance = target['labels']['instance']
                    print(f"    {status} {job} ({instance})")
                
                return {
                    'total': len(targets),
                    'healthy': len(healthy_targets),
                    'unhealthy': len(targets) - len(healthy_targets)
                }
            else:
                print("  ❌ Failed to get targets from Prometheus")
                return {'total': 0, 'healthy': 0, 'unhealthy': 0}
                
        except Exception as e:
            print(f"  ❌ Error testing Prometheus targets: {e}")
            return {'total': 0, 'healthy': 0, 'unhealthy': 0}
    
    def test_alerting_rules(self) -> Dict[str, int]:
        """Test Prometheus alerting rules."""
        print("\n🚨 Testing alerting rules...")
        
        try:
            response = requests.get(f"{self.prometheus_url}/api/v1/rules")
            data = response.json()
            
            if data['status'] == 'success':
                groups = data['data']['groups']
                total_rules = sum(len(group['rules']) for group in groups)
                firing_alerts = []
                
                for group in groups:
                    for rule in group['rules']:
                        if rule.get('type') == 'alerting' and rule.get('state') == 'firing':
                            firing_alerts.append(rule)
                
                print(f"  Total alert rules: {total_rules}")
                print(f"  Firing alerts: {len(firing_alerts)}")
                
                if firing_alerts:
                    print("  Currently firing alerts:")
                    for alert in firing_alerts:
                        print(f"    🔥 {alert['name']}")
                
                return {
                    'total_rules': total_rules,
                    'firing_alerts': len(firing_alerts)
                }
            else:
                print("  ❌ Failed to get rules from Prometheus")
                return {'total_rules': 0, 'firing_alerts': 0}
                
        except Exception as e:
            print(f"  ❌ Error testing alerting rules: {e}")
            return {'total_rules': 0, 'firing_alerts': 0}
    
    def test_grafana_datasources(self) -> List[str]:
        """Test Grafana datasource connections."""
        print("\n📊 Testing Grafana datasources...")
        
        # Default admin credentials for testing
        auth = ('admin', 'your_KEY_goes_here')
        
        try:
            response = requests.get(
                f"{self.grafana_url}/api/datasources",
                auth=auth,
                timeout=10
            )
            
            if response.status_code == 200:
                datasources = response.json()
                working_datasources = []
                
                for ds in datasources:
                    # Test datasource connection
                    test_response = requests.get(
                        f"{self.grafana_url}/api/datasources/{ds['id']}/health",
                        auth=auth,
                        timeout=10
                    )
                    
                    if test_response.status_code == 200:
                        working_datasources.append(ds['name'])
                        print(f"  ✅ {ds['name']} ({ds['type']})")
                    else:
                        print(f"  ❌ {ds['name']} ({ds['type']}) - Connection failed")
                
                return working_datasources
            else:
                print("  ❌ Failed to get datasources from Grafana")
                return []
                
        except Exception as e:
            print(f"  ❌ Error testing Grafana datasources: {e}")
            return []
    
    def test_elasticsearch_indices(self) -> Dict[str, int]:
        """Test Elasticsearch indices."""
        print("\n📈 Testing Elasticsearch indices...")
        
        try:
            response = requests.get(f"{self.elasticsearch_url}/_cat/indices?format=json")
            indices = response.json()
            
            electra_indices = [idx for idx in indices if idx['index'].startswith('electra-')]
            
            print(f"  Total indices: {len(indices)}")
            print(f"  Electra indices: {len(electra_indices)}")
            
            for idx in electra_indices:
                print(f"    📄 {idx['index']}: {idx['docs.count']} docs, {idx['store.size']}")
            
            return {
                'total_indices': len(indices),
                'electra_indices': len(electra_indices),
                'total_docs': sum(int(idx.get('docs.count', 0)) for idx in electra_indices)
            }
            
        except Exception as e:
            print(f"  ❌ Error testing Elasticsearch indices: {e}")
            return {'total_indices': 0, 'electra_indices': 0, 'total_docs': 0}
    
    def generate_test_metrics(self, count: int = 100):
        """Generate test metrics by making requests to Django."""
        print(f"\n📊 Generating {count} test metrics...")
        
        endpoints = [
            '/api/health/',
            '/metrics',
            '/api/auth/profile/',  # This might return 401, which is fine for testing
            '/api/elections/',     # This might return 401, which is fine for testing
        ]
        
        successful_requests = 0
        
        for i in range(count):
            endpoint = random.choice(endpoints)
            try:
                response = requests.get(f"{self.django_url}{endpoint}", timeout=5)
                if response.status_code in [200, 401, 403]:  # Expected responses
                    successful_requests += 1
                
                if i % 20 == 0:
                    print(f"  Generated {i + 1}/{count} requests...")
                    
                # Small delay to avoid overwhelming the server
                time.sleep(0.1)
                
            except Exception as e:
                print(f"  ⚠️  Request {i + 1} failed: {e}")
        
        print(f"  ✅ Generated {successful_requests} successful test requests")
        return successful_requests
    
    def generate_test_logs(self, count: int = 50):
        """Generate test log entries."""
        print(f"\n📝 Generating {count} test log entries...")
        
        # This would normally be done through the application
        # For now, we'll just log some test messages
        
        test_logs = []
        for i in range(count):
            log_entry = {
                'timestamp': datetime.now().isoformat(),
                'level': random.choice(['INFO', 'WARNING', 'ERROR']),
                'message': f'Test log entry {i + 1}',
                'logger': 'test_suite',
                'request_id': str(uuid.uuid4()),
                'test_data': True
            }
            test_logs.append(log_entry)
        
        print(f"  ✅ Generated {len(test_logs)} test log entries")
        return test_logs
    
    def test_alert_firing(self):
        """Test alert firing by creating error conditions."""
        print("\n🚨 Testing alert firing...")
        
        print("  Creating test error conditions...")
        
        # Generate 404 errors to potentially trigger error rate alerts
        for i in range(20):
            try:
                requests.get(f"{self.django_url}/api/nonexistent-endpoint-{i}", timeout=2)
            except:
                pass
        
        print("  ✅ Generated error conditions for alert testing")
        print("  Check Prometheus alerts in a few minutes to see if alerts fired")
    
    def run_comprehensive_test(self):
        """Run all monitoring tests."""
        print("🚀 Starting comprehensive monitoring system test\n")
        start_time = time.time()
        
        # Test service health
        health_results = self.test_service_health()
        
        # Test Prometheus
        target_results = self.test_prometheus_targets()
        alert_results = self.test_alerting_rules()
        
        # Test Grafana
        datasource_results = self.test_grafana_datasources()
        
        # Test Elasticsearch
        es_results = self.test_elasticsearch_indices()
        
        # Generate test data
        metrics_generated = self.generate_test_metrics(50)
        logs_generated = self.generate_test_logs(25)
        
        # Test alerting (optional)
        self.test_alert_firing()
        
        # Summary
        elapsed_time = time.time() - start_time
        
        print(f"\n📋 Test Summary ({elapsed_time:.1f}s)")
        print("=" * 50)
        
        healthy_services = sum(health_results.values())
        total_services = len(health_results)
        print(f"Service Health: {healthy_services}/{total_services} services healthy")
        
        print(f"Prometheus: {target_results['healthy']}/{target_results['total']} targets healthy")
        print(f"Alerting: {alert_results['total_rules']} rules, {alert_results['firing_alerts']} firing")
        print(f"Grafana: {len(datasource_results)} datasources working")
        print(f"Elasticsearch: {es_results['electra_indices']} indices, {es_results['total_docs']} docs")
        print(f"Test Data: {metrics_generated} metrics, {len(logs_generated)} logs generated")
        
        # Overall health score
        health_score = (
            (healthy_services / total_services) * 30 +
            (target_results['healthy'] / max(target_results['total'], 1)) * 25 +
            (len(datasource_results) / 4) * 20 +  # Expect 4 datasources
            (1 if es_results['electra_indices'] > 0 else 0) * 15 +
            (1 if metrics_generated > 0 else 0) * 10
        )
        
        print(f"\nOverall Health Score: {health_score:.1f}/100")
        
        if health_score >= 80:
            print("🎉 Monitoring system is working well!")
        elif health_score >= 60:
            print("⚠️  Monitoring system has some issues that should be addressed")
        else:
            print("❌ Monitoring system has significant issues")
        
        return health_score


def main():
    parser = argparse.ArgumentParser(description='Test Electra monitoring system')
    parser.add_argument('--base-url', default='http://localhost',
                       help='Base URL for services (default: http://localhost)')
    parser.add_argument('--generate-data', type=int, default=0,
                       help='Number of test data points to generate')
    parser.add_argument('--test-alerts', action='store_true',
                       help='Test alert firing by creating error conditions')
    parser.add_argument('--quick', action='store_true',
                       help='Run quick health check only')
    
    args = parser.parse_args()
    
    tester = MonitoringTester(base_url=args.base_url)
    
    if args.quick:
        health_results = tester.test_service_health()
        healthy_count = sum(health_results.values())
        total_count = len(health_results)
        print(f"\nQuick Health Check: {healthy_count}/{total_count} services healthy")
        return 0 if healthy_count == total_count else 1
    
    if args.generate_data > 0:
        tester.generate_test_metrics(args.generate_data)
        tester.generate_test_logs(args.generate_data // 2)
        return 0
    
    if args.test_alerts:
        tester.test_alert_firing()
        return 0
    
    # Run comprehensive test
    health_score = tester.run_comprehensive_test()
    return 0 if health_score >= 70 else 1


if __name__ == '__main__':
    exit(main())