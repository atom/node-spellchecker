{
  "targets": [
    {
      "target_name": "spellchecker",
      "sources": [ "src/main.cc", "src/spellchecker_mac.mm" ],
      'link_settings': {
        'libraries': [
          '$(SDKROOT)/System/Library/Frameworks/AppKit.framework',
        ],
      },
    }
  ]
}
