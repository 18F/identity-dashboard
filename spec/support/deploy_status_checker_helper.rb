module DeployStatusCheckerHelper
  def stub_status_json
    {
      sha: 'sha',
      branch: 'branch',
      user: 'user',
      timestamp: '20161102201213',
    }.as_json
  end

  def stub_deploy_status
    stub_request(:get, %r{https://secure\.login\.gov/api/deploy\.json})
      .to_return(body: stub_status_json.to_json)
    stub_request(:get, %r{https://.*\.staging\.login\.gov/api/deploy\.json})
      .to_return(body: stub_status_json.to_json)
    stub_request(:get, %r{https://.*\.int\.identitysandbox\.gov/api/deploy\.json})
      .to_return(body: stub_status_json.to_json)
    stub_request(:get, %r{https://(int|staging|prod)-.*\.cloud\.gov/api/deploy\.json})
      .to_return(body: stub_status_json.to_json)
    stub_request(:get, %r{https://checking-deploy.pivcac.(dev|int|staging|prod).(login|identitysandbox).gov/api/deploy\.json})
      .to_return(body: stub_status_json.to_json)
    stub_request(:get, %r{https://.*\.dev\.identitysandbox\.gov/api/deploy\.json})
      .to_return(status: 404)
    stub_request(:get, %r{https://dev-.*\.cloud\.gov/api/deploy\.json})
      .to_return(status: 404)
    stub_request(:get, %r{https://.*\.qa\.identitysandbox\.gov/api/deploy\.json})
      .to_timeout
    stub_request(:get, %r{https://qa-.*\.cloud\.gov/api/deploy\.json})
      .to_timeout
  end
end
