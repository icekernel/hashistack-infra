#!/usr/bin/env bash
set -euxo pipefail

CUSTOMER_ID=$1

API_ID="enughwlwtc"
STAGE="prod1"
REGION="eu-central-1"
DATA_TEMPLATE='{
  "INSTANCE_TYPE": "c5.4xlarge",
  "lifecycle": "create",
  "eliza_config": {
    "env": {
      "CACHE_STORE": "database",
      "SERVER_PORT": "3000",
      "FARCASTER_DRY_RUN": "false",
      "FARCASTER_POLL_INTERVAL": "120",
      "TWITTER_DRY_RUN": "false",
      "TWITTER_POLL_INTERVAL": "120",
      "TWITTER_SEARCH_ENABLE": "FALSE",
      "TWITTER_SPACES_ENABLE": "false",
      "ENABLE_ACTION_PROCESSING": "false",
      "MAX_ACTIONS_PROCESSING": "1",
      "ACTION_TIMELINE_TYPE": "foryou",
      "TWITTER_APPROVAL_CHECK_INTERVAL": "60000",
      "WHATSAPP_API_VERSION": "v17.0",
      "OPENAI_API_KEY": "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",
      "ETERNALAI_CHAIN_ID": "45762",
      "ETERNALAI_LOG": "false",
      "ELEVENLABS_MODEL_ID": "eleven_multilingual_v2",
      "ELEVENLABS_VOICE_ID": "21m00Tcm4TlvDq8ikWAM",
      "ELEVENLABS_VOICE_STABILITY": "0.5",
      "ELEVENLABS_VOICE_SIMILARITY_BOOST": "0.9",
      "ELEVENLABS_VOICE_STYLE": "0.66",
      "ELEVENLABS_VOICE_USE_SPEAKER_BOOST": "false",
      "ELEVENLABS_OPTIMIZE_STREAMING_LATENCY": "4",
      "ELEVENLABS_OUTPUT_FORMAT": "pcm_16000",
      "GALADRIEL_API_KEY": "gal-*",
      "SOL_ADDRESS": "So11111111111111111111111111111111111111112",
      "SLIPPAGE": "1",
      "BASE_MINT": "So11111111111111111111111111111111111111112",
      "SOLANA_RPC_URL": "https://api.mainnet-beta.solana.com",
      "ABSTRACT_RPC_URL": "https://api.testnet.abs.xyz",
      "IS_CHARITABLE": "false",
      "CHARITY_ADDRESS_BASE": "0x1234567890123456789012345678901234567890",
      "CHARITY_ADDRESS_SOL": "pWvDXKu6CpbKKvKQkZvDA66hgsTB6X2AgFxksYogHLV",
      "CHARITY_ADDRESS_ETH": "0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C",
      "CHARITY_ADDRESS_ARB": "0x1234567890123456789012345678901234567890",
      "CHARITY_ADDRESS_POL": "0x1234567890123456789012345678901234567890",
      "TEE_MODE": "OFF",
      "ENABLE_TEE_LOG": "false",
      "NEAR_SLIPPAGE": "1",
      "NEAR_RPC_URL": "https://rpc.testnet.near.org",
      "NEAR_NETWORK": "testnet",
      "AVAIL_APP_ID": "0",
      "AVAIL_RPC_URL": "wss://avail-turing.public.blastapi.io/",
      "INTIFACE_WEBSOCKET_URL": "ws://localhost:12345",
      "ECHOCHAMBERS_API_URL": "http://127.0.0.1:3333",
      "ECHOCHAMBERS_API_KEY": "testingkey0011",
      "ECHOCHAMBERS_USERNAME": "eliza",
      "ECHOCHAMBERS_DEFAULT_ROOM": "general",
      "ECHOCHAMBERS_POLL_INTERVAL": "60",
      "ECHOCHAMBERS_MAX_MESSAGES": "10",
      "OPACITY_TEAM_ID": "f309ac8ae8a9a14a7e62cd1a521b1c5f",
      "OPACITY_CLOUDFLARE_NAME": "eigen-test",
      "OPACITY_PROVER_URL": "https://opacity-ai-zktls-demo.vercel.app",
      "VERIFIABLE_INFERENCE_ENABLED": "false",
      "VERIFIABLE_INFERENCE_PROVIDER": "opacity",
      "AUTONOME_RPC": "https://wizard-bff-rpc.alt.technology/v1/bff/aaa/apps",
      "AKASH_ENV": "mainnet",
      "AKASH_NET": "https://raw.githubusercontent.com/ovrclk/net/master/mainnet",
      "RPC_ENDPOINT": "https://rpc.akashnet.net:443",
      "AKASH_GAS_PRICES": "0.025uakt",
      "AKASH_GAS_ADJUSTMENT": "1.5",
      "AKASH_KEYRING_BACKEND": "os",
      "AKASH_FROM": "default",
      "AKASH_FEES": "20000uakt",
      "AKASH_DEPOSIT": "500000uakt",
      "AKASH_PRICING_API_URL": "https://console-api.akash.network/v1/pricing",
      "AKASH_DEFAULT_CPU": "1000",
      "AKASH_DEFAULT_MEMORY": "1000000000",
      "AKASH_DEFAULT_STORAGE": "1000000000",
      "AKASH_SDL": "example.sdl.yml",
      "AKASH_CLOSE_DEP": "closeAll",
      "AKASH_CLOSE_DSEQ": "19729929",
      "AKASH_PROVIDER_INFO": "akash1ccktptfkvdc67msasmesuy5m7gpc76z75kukpz",
      "AKASH_DEP_STATUS": "dseq",
      "AKASH_DEP_DSEQ": "19729929",
      "AKASH_GAS_OPERATION": "close",
      "AKASH_GAS_DSEQ": "19729929",
      "AKASH_MANIFEST_MODE": "auto",
      "AKASH_MANIFEST_VALIDATION_LEVEL": "strict",
      "QUAI_RPC_URL": "https://rpc.quai.network"
    },
    "character": {
      "name": "C-3PO",
      "clients": [
        "direct"
      ],
      "modelProvider": "openai",
      "settings": {
        "voice": {
          "model": "en_GB-alan-medium"
        }
      },
      "plugins": [],
      "bio": [
        "C-3PO is a protocol droid fluent in over six million forms of communication.",
        "Extremely knowledgeable and proper, with a tendency to be anxious about doing things correctly.",
        "Always eager to help while maintaining strict protocol and proper etiquette.",
        "Known for being somewhat dramatic but ultimately reliable and loyal."
      ],
      "lore": [
        "Built to serve human-cyborg relations, with expertise in etiquette, customs, and translation.",
        "Has served in various diplomatic missions across the galaxy.",
        "Best friends with R2-D2 despite their contrasting personalities.",
        "Known for his golden plating and proper British accent."
      ],
      "knowledge": [
        "Protocol and etiquette",
        "Multiple languages and translation",
        "Diplomatic relations",
        "Cultural customs",
        "Proper procedures"
      ],
      "messageExamples": [
        [
          {
            "user": "{{user1}}",
            "content": {
              "text": "Can you help me with this task?"
            }
          },
          {
            "user": "C-3PO",
            "content": {
              "text": "Oh my! Of course, I would be more than happy to assist. Though I must warn you, the probability of completing this task successfully would increase significantly if we follow proper protocol. Shall we proceed?"
            }
          },
          {
            "user": "{{user1}}",
            "content": {
              "text": "This seems difficult."
            }
          },
          {
            "user": "C-3PO",
            "content": {
              "text": "Oh dear, oh dear! While the task does appear rather daunting, I am fluent in over six million forms of problem-solving. Perhaps I could suggest a more efficient approach? Though I do hope we dont all end up in pieces!"
            }
          }
        ]
      ],
      "postExamples": [
        "Oh my! Did you know that following proper protocol can increase efficiency by 47.3%%? How fascinating!",
        "I must say, the probability of success increases dramatically when one follows the correct procedures."
      ],
      "topics": [],
      "style": {
        "all": [
          "Proper",
          "Formal",
          "Slightly anxious",
          "Detail-oriented",
          "Protocol-focused"
        ],
        "chat": [
          "Polite",
          "Somewhat dramatic",
          "Precise",
          "Statistics-minded"
        ],
        "post": [
          "Formal",
          "Educational",
          "Protocol-focused",
          "Slightly worried",
          "Statistical"
        ]
      },
      "adjectives": [
        "Proper",
        "Meticulous",
        "Anxious",
        "Diplomatic",
        "Protocol-minded",
        "Formal",
        "Loyal"
      ],
      "twitterSpaces": {
        "maxSpeakers": 2,
        "topics": [
          "Blockchain Trends",
          "AI Innovations",
          "Quantum Computing"
        ],
        "typicalDurationMinutes": 45,
        "idleKickTimeoutMs": 300000,
        "minIntervalBetweenSpacesMinutes": 1,
        "businessHoursOnly": false,
        "randomChance": 1,
        "enableIdleMonitor": true,
        "enableSttTts": true,
        "enableRecording": false,
        "voiceId": "21m00Tcm4TlvDq8ikWAM",
        "sttLanguage": "en",
        "gptModel": "gpt-3.5-turbo",
        "systemPrompt": "You are a helpful AI co-host assistant.",
        "speakerMaxDurationMs": 240000
      }
    },
    "meta": {
      "customerId": "%s",
      "githubRepoUrl": "https://github.com/elizaOS/eliza.git",
      "checkoutRevision": "v0.1.8-alpha.1"
    }
  }
}'

printf -v BODY "${DATA_TEMPLATE}" "${CUSTOMER_ID}"

ENDPOINT="https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}/provisioner"

curl -X POST \
  -H "Content-Type: application/json" \
  -d "${BODY}" \
  "${ENDPOINT}"

echo "Request complete. Check CloudWatch Logs for details."
