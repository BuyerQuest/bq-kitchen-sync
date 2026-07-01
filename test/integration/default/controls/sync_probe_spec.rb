control 'bq-kitchen-sync-upload' do
  impact 1.0
  title 'Kitchen transport uploads and converges the fixture cookbook'

  describe file('/tmp/bq-kitchen-sync-payload.txt') do
    it { should exist }
    its('content') { should match(/delivered through the Test Kitchen transport/) }
  end

  describe file('/tmp/bq-kitchen-sync-marker.txt') do
    it { should exist }
    its('content') { should match(/bq-kitchen-sync converged via/) }
  end
end
