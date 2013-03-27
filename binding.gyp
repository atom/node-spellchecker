{
  "targets": [
    {
      "target_name": "spellchecker",
      "sources": [ "main.cc", "spellchecker_mac.mm" ],
      'link_settings': {
        'libraries': [
          '$(SDKROOT)/System/Library/Frameworks/AppKit.framework',
        ],
      },
    }
  ]
}

