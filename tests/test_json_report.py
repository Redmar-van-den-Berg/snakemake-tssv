import pytest
import os
import json


@pytest.mark.workflow('integration-two-samples')
@pytest.mark.parametrize('sample', ['sample1', 'sample2'])
def test_json_files_exist(workflow_dir, sample):
    file_path = os.path.join(workflow_dir, f'{sample}/tssv/001-forward.json')
    assert os.path.exists(file_path)


@pytest.mark.workflow('integration-two-samples')
@pytest.mark.parametrize('sample', ['sample1', 'sample2'])
def test_json_merged_exists(workflow_dir, sample):
    file_path = os.path.join(workflow_dir, f'{sample}/tssv/merged.json')
    assert os.path.exists(file_path)


@pytest.mark.workflow('integration-two-samples')
@pytest.mark.parametrize('field, value', [
    ('allele', 'G'),
    ('total', 31),
    ('forward', 13),
    ('reverse', 18)
    ])
def test_json_content_sample1(workflow_dir, field, value):
    path = os.path.join(workflow_dir, 'sample1/tssv/001-forward.json')
    with open(path) as fin:
        data = json.load(fin)

    assert data['marker']['chrM:8860']['new'][0][field] == value


@pytest.mark.workflow('integration-two-samples')
@pytest.mark.parametrize('field, value', [
    ('allele', 'G'),
    ('total', 27),
    ('forward', 11),
    ('reverse', 16)
    ])
def test_json_content_sample2(workflow_dir, field, value):
    path = os.path.join(workflow_dir, 'sample2/tssv/001-forward.json')
    with open(path) as fin:
        data = json.load(fin)

    assert data['marker']['chrM:8860']['new'][0][field] == value


@pytest.mark.workflow('integration-two-samples')
@pytest.mark.parametrize('field, value', [
    ('total', 53),
    ('forward', 24),
    ('reverse', 29)
    ])
def test_merged_json_content_sample1(workflow_dir, field, value):
    path = os.path.join(workflow_dir, 'sample1/tssv/merged.json')
    with open(path) as fin:
        data = json.load(fin)

    assert data['chrM:8860']['G'][field] == value


@pytest.mark.workflow('integration-two-samples')
@pytest.mark.parametrize('field, value', [
    ('total', 47),
    ('forward', 24),
    ('reverse', 23)
    ])
def test_merged_json_content_sample2(workflow_dir, field, value):
    path = os.path.join(workflow_dir, 'sample2/tssv/merged.json')
    with open(path) as fin:
        data = json.load(fin)

    assert data['chrM:8860']['G'][field] == value
