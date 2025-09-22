"""
Unit tests for analytics models.

This module tests the analytics models including cache management,
export verification, and data integrity features.
"""
import hashlib
import json
import uuid
from datetime import timedelta

import pytest
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.test import TestCase
from django.utils import timezone

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.analytics.models import AnalyticsCache, ExportVerification

User = get_user_model()


@pytest.mark.unit
class TestAnalyticsModels(TestCase):
    """Test cases for analytics models."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            full_name='Admin User',
            role=UserRole.ADMIN,
            staff_id='ADMIN001'
        )
        
        self.election = Election.objects.create(
            title='Test Election',
            description='Test election for analytics',
            start_time=timezone.now() - timedelta(days=7),
            end_time=timezone.now() + timedelta(days=7),
            status=ElectionStatus.ACTIVE,
            created_by=self.admin_user
        )
        
        self.test_data = {
            'overall_turnout': 75.0,
            'per_election': [
                {
                    'election_id': str(self.election.id),
                    'turnout_percentage': 75.0,
                    'votes_cast': 150,
                    'eligible_voters': 200
                }
            ],
            'summary': {
                'total_elections': 1,
                'total_votes_cast': 150
            }
        }


class TestAnalyticsCache(TestAnalyticsModels):
    """Test cases for AnalyticsCache model."""
    
    def test_analytics_cache_creation(self):
        """Test creating an analytics cache entry."""
        cache_entry = AnalyticsCache.objects.create(
            cache_key='test_turnout_all',
            election=self.election,
            data=self.test_data,
            calculation_duration=2.5,
            expires_at=timezone.now() + timedelta(hours=1)
        )
        
        self.assertIsNotNone(cache_entry.id)
        self.assertEqual(cache_entry.cache_key, 'test_turnout_all')
        self.assertEqual(cache_entry.election, self.election)
        self.assertEqual(cache_entry.data, self.test_data)
        self.assertEqual(cache_entry.calculation_duration, 2.5)
        
        # Verify data hash was generated
        self.assertIsNotNone(cache_entry.data_hash)
        self.assertEqual(len(cache_entry.data_hash), 64)  # SHA-256 hex length
    
    def test_analytics_cache_data_hash_generation(self):
        """Test that data hash is automatically generated on save."""
        cache_entry = AnalyticsCache(
            cache_key='test_hash_generation',
            data=self.test_data,
            calculation_duration=1.0,
            expires_at=timezone.now() + timedelta(hours=1)
        )
        
        # Hash should be None before save
        self.assertIsNone(cache_entry.data_hash)
        
        cache_entry.save()
        
        # Hash should be generated after save
        self.assertIsNotNone(cache_entry.data_hash)
        
        # Verify hash is correct
        expected_hash = hashlib.sha256(
            json.dumps(self.test_data, sort_keys=True).encode()
        ).hexdigest()
        self.assertEqual(cache_entry.data_hash, expected_hash)
    
    def test_analytics_cache_unique_cache_key(self):
        """Test that cache keys must be unique."""
        AnalyticsCache.objects.create(
            cache_key='unique_test_key',
            data=self.test_data,
            calculation_duration=1.0,
            expires_at=timezone.now() + timedelta(hours=1)
        )
        
        # Creating another entry with same cache_key should fail
        with self.assertRaises(Exception):  # IntegrityError
            AnalyticsCache.objects.create(
                cache_key='unique_test_key',
                data={'different': 'data'},
                calculation_duration=2.0,
                expires_at=timezone.now() + timedelta(hours=2)
            )
    
    def test_analytics_cache_expiration_validation(self):
        """Test validation of expiration time."""
        # Expires_at in the past should fail validation
        cache_entry = AnalyticsCache(
            cache_key='test_expiration',
            data=self.test_data,
            calculation_duration=1.0,
            expires_at=timezone.now() - timedelta(hours=1)  # Past time
        )
        
        with self.assertRaises(ValidationError):
            cache_entry.clean()
    
    def test_analytics_cache_is_expired(self):
        """Test is_expired method."""
        # Create expired cache entry
        expired_cache = AnalyticsCache.objects.create(
            cache_key='test_expired',
            data=self.test_data,
            calculation_duration=1.0,
            expires_at=timezone.now() - timedelta(seconds=1)
        )
        
        self.assertTrue(expired_cache.is_expired())
        
        # Create valid cache entry
        valid_cache = AnalyticsCache.objects.create(
            cache_key='test_valid',
            data=self.test_data,
            calculation_duration=1.0,
            expires_at=timezone.now() + timedelta(hours=1)
        )
        
        self.assertFalse(valid_cache.is_expired())
    
    def test_analytics_cache_mark_accessed(self):
        """Test mark_accessed method."""
        cache_entry = AnalyticsCache.objects.create(
            cache_key='test_access_tracking',
            data=self.test_data,
            calculation_duration=1.0,
            expires_at=timezone.now() + timedelta(hours=1)
        )
        
        # Initially should have no access data
        self.assertIsNone(cache_entry.last_accessed)
        self.assertEqual(cache_entry.access_count, 0)
        
        # Mark as accessed
        cache_entry.mark_accessed()
        
        # Refresh from database
        cache_entry.refresh_from_db()
        
        self.assertIsNotNone(cache_entry.last_accessed)
        self.assertEqual(cache_entry.access_count, 1)
        
        # Mark as accessed again
        cache_entry.mark_accessed()
        cache_entry.refresh_from_db()
        
        self.assertEqual(cache_entry.access_count, 2)
    
    def test_analytics_cache_verify_integrity(self):
        """Test data integrity verification."""
        cache_entry = AnalyticsCache.objects.create(
            cache_key='test_integrity',
            data=self.test_data,
            calculation_duration=1.0,
            expires_at=timezone.now() + timedelta(hours=1)
        )
        
        # Should verify successfully initially
        self.assertTrue(cache_entry.verify_integrity())
        
        # Manually corrupt the data (simulate tampering)
        cache_entry.data['corrupted'] = 'bad_data'
        
        # Should fail verification now
        self.assertFalse(cache_entry.verify_integrity())
    
    def test_analytics_cache_string_representation(self):
        """Test string representation of cache entry."""
        cache_entry = AnalyticsCache.objects.create(
            cache_key='test_str_repr',
            data=self.test_data,
            calculation_duration=1.0,
            expires_at=timezone.now() + timedelta(hours=1)
        )
        
        str_repr = str(cache_entry)
        self.assertIn('test_str_repr', str_repr)
        self.assertIn('AnalyticsCache', str_repr)


class TestExportVerification(TestAnalyticsModels):
    """Test cases for ExportVerification model."""
    
    def test_export_verification_creation(self):
        """Test creating an export verification record."""
        verification = ExportVerification.objects.create(
            export_type='csv',
            content_hash='abc123def456',
            filename='test_export.csv',
            file_size=1024,
            export_params={'data_type': 'turnout'},
            requested_by=self.admin_user,
            request_ip='192.168.1.100'
        )
        
        self.assertIsNotNone(verification.id)
        self.assertEqual(verification.export_type, 'csv')
        self.assertEqual(verification.content_hash, 'abc123def456')
        self.assertEqual(verification.filename, 'test_export.csv')
        self.assertEqual(verification.file_size, 1024)
        self.assertEqual(verification.requested_by, self.admin_user)
        self.assertEqual(verification.request_ip, '192.168.1.100')
        
        # Verification hash should be generated automatically
        self.assertIsNotNone(verification.verification_hash)
        self.assertEqual(len(verification.verification_hash), 64)  # SHA-256 hex length
    
    def test_export_verification_hash_generation(self):
        """Test automatic generation of verification hash."""
        verification = ExportVerification(
            export_type='xlsx',
            content_hash='def456ghi789',
            filename='test_export.xlsx',
            file_size=2048,
            export_params={'data_type': 'participation'},
            requested_by=self.admin_user,
            request_ip='10.0.0.1'
        )
        
        # Verification hash should be None before save
        self.assertIsNone(verification.verification_hash)
        
        verification.save()
        
        # Verification hash should be generated after save
        self.assertIsNotNone(verification.verification_hash)
        self.assertEqual(len(verification.verification_hash), 64)
    
    def test_export_verification_unique_verification_hash(self):
        """Test that verification hashes are unique."""
        verification1 = ExportVerification.objects.create(
            export_type='pdf',
            content_hash='unique123',
            filename='export1.pdf',
            file_size=512,
            export_params={'data_type': 'time_series'},
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        
        verification2 = ExportVerification.objects.create(
            export_type='pdf',
            content_hash='unique456',  # Different content hash
            filename='export2.pdf',
            file_size=512,
            export_params={'data_type': 'time_series'},
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        
        # Verification hashes should be different
        self.assertNotEqual(verification1.verification_hash, verification2.verification_hash)
    
    def test_export_verification_create_for_export(self):
        """Test create_for_export class method."""
        content = b"This is test export content"
        export_params = {
            'data_type': 'turnout',
            'election_id': str(self.election.id)
        }
        
        verification = ExportVerification.create_for_export(
            export_type='csv',
            content=content,
            filename='turnout_export.csv',
            export_params=export_params,
            requested_by=self.admin_user,
            request_ip='192.168.1.1'
        )
        
        # Verify all fields are set correctly
        self.assertEqual(verification.export_type, 'csv')
        self.assertEqual(verification.filename, 'turnout_export.csv')
        self.assertEqual(verification.file_size, len(content))
        self.assertEqual(verification.export_params, export_params)
        self.assertEqual(verification.requested_by, self.admin_user)
        self.assertEqual(verification.request_ip, '192.168.1.1')
        
        # Verify content hash is correct
        expected_hash = hashlib.sha256(content).hexdigest()
        self.assertEqual(verification.content_hash, expected_hash)
        
        # Verify verification hash was generated
        self.assertIsNotNone(verification.verification_hash)
    
    def test_export_verification_verify_content(self):
        """Test content verification method."""
        original_content = b"Original export content"
        
        verification = ExportVerification.create_for_export(
            export_type='xlsx',
            content=original_content,
            filename='test.xlsx',
            export_params={},
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        
        # Should verify successfully with original content
        self.assertTrue(verification.verify_content(original_content))
        
        # Should fail with different content
        modified_content = b"Modified export content"
        self.assertFalse(verification.verify_content(modified_content))
    
    def test_export_verification_string_representation(self):
        """Test string representation of export verification."""
        verification = ExportVerification.objects.create(
            export_type='pdf',
            content_hash='test123',
            filename='test_report.pdf',
            file_size=1024,
            export_params={},
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        
        str_repr = str(verification)
        self.assertIn('Export(pdf)', str_repr)
        self.assertIn('test_report.pdf', str_repr)
    
    def test_export_verification_export_params_default(self):
        """Test that export_params defaults to empty dict."""
        verification = ExportVerification.objects.create(
            export_type='csv',
            content_hash='test456',
            filename='simple_export.csv',
            file_size=256,
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
            # export_params not provided
        )
        
        self.assertEqual(verification.export_params, {})
    
    def test_export_verification_choice_validation(self):
        """Test export type choice validation."""
        # Valid export type should work
        verification = ExportVerification(
            export_type='csv',
            content_hash='valid123',
            filename='valid.csv',
            file_size=100,
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        verification.full_clean()  # Should not raise exception
        
        # Invalid export type should fail validation
        verification_invalid = ExportVerification(
            export_type='invalid_type',
            content_hash='invalid123',
            filename='invalid.txt',
            file_size=100,
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        
        with self.assertRaises(ValidationError):
            verification_invalid.full_clean()
    
    def test_export_verification_related_name(self):
        """Test related name functionality."""
        verification1 = ExportVerification.objects.create(
            export_type='csv',
            content_hash='user_test1',
            filename='export1.csv',
            file_size=100,
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        
        verification2 = ExportVerification.objects.create(
            export_type='xlsx',
            content_hash='user_test2',
            filename='export2.xlsx',
            file_size=200,
            requested_by=self.admin_user,
            request_ip='127.0.0.1'
        )
        
        # Should be able to access user's export requests
        user_exports = self.admin_user.export_requests.all()
        self.assertEqual(user_exports.count(), 2)
        self.assertIn(verification1, user_exports)
        self.assertIn(verification2, user_exports)
    
    def test_analytics_cache_election_optional(self):
        """Test that election field is optional in AnalyticsCache."""
        # Should be able to create cache entry without election (for global analytics)
        cache_entry = AnalyticsCache.objects.create(
            cache_key='global_analytics',
            data={'global_metric': 100},
            calculation_duration=1.0,
            expires_at=timezone.now() + timedelta(hours=1)
            # election not provided
        )
        
        self.assertIsNone(cache_entry.election)
        self.assertEqual(cache_entry.cache_key, 'global_analytics')
    
    def test_model_meta_options(self):
        """Test model meta options are correctly set."""
        # Test AnalyticsCache meta options
        cache_meta = AnalyticsCache._meta
        self.assertEqual(cache_meta.db_table, 'analytics_cache')
        self.assertEqual(cache_meta.verbose_name, 'Analytics Cache')
        self.assertEqual(cache_meta.verbose_name_plural, 'Analytics Cache')
        self.assertEqual(cache_meta.ordering, ['-created_at'])
        
        # Test ExportVerification meta options
        export_meta = ExportVerification._meta
        self.assertEqual(export_meta.db_table, 'analytics_export_verification')
        self.assertEqual(export_meta.verbose_name, 'Export Verification')
        self.assertEqual(export_meta.verbose_name_plural, 'Export Verifications')
        self.assertEqual(export_meta.ordering, ['-created_at'])
    
    def test_model_indexes(self):
        """Test that database indexes are properly defined."""
        # Get model indexes
        cache_indexes = AnalyticsCache._meta.indexes
        export_indexes = ExportVerification._meta.indexes
        
        # AnalyticsCache should have indexes on key fields
        cache_index_fields = [idx.fields for idx in cache_indexes]
        self.assertTrue(any('cache_key' in fields for fields in cache_index_fields))
        self.assertTrue(any('created_at' in fields for fields in cache_index_fields))
        self.assertTrue(any('expires_at' in fields for fields in cache_index_fields))
        
        # ExportVerification should have indexes on key fields
        export_index_fields = [idx.fields for idx in export_indexes]
        self.assertTrue(any('verification_hash' in fields for fields in export_index_fields))
        self.assertTrue(any('content_hash' in fields for fields in export_index_fields))
        self.assertTrue(any('created_at' in fields for fields in export_index_fields))