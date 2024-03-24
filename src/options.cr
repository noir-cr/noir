def default_options
  noir_options = {
    :base              => "",
    :color             => "yes",
    :config_file       => "",
    :concurrency       => "100",
    :debug             => "no",
    :exclude_techs     => "",
    :format            => "plain",
    :include_path      => "no",
    :nolog             => "no",
    :output            => "",
    :send_es           => "",
    :send_proxy        => "",
    :send_req          => "no",
    :send_with_headers => "",
    :set_pvalue        => "",
    :techs             => "",
    :url               => "",
    :use_filters       => "",
    :use_matchers      => "",
    :tagger            => "no",
    :use_taggers       => "",
  }

  noir_options
end
