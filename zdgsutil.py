def copy_file_to_gcs(filepath, bucket, gcs_path):
    return ['gsutil',
            'cp',
            filepath,
            'gs://{}/{}'.format(bucket, gcs_path)]

def remove_from_from_gcs(bucket, gcs_path):
    # prevent entire buckets from getting deleted here
    assert gcs_path is not None
    assert gcs_path != ''
    assert gcs_path != '*'
    assert gcs_path != '**'
    return ['gsutil',
            'rm',
            'gs://{}/{}'.format(bucket, gcs_path)]
