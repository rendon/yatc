require 'spec_helper'

RSpec.describe TwitterClient do
  let(:ck) { ENV['TWITTER_CONSUMER_KEY'] }
  let(:cs) { ENV['TWITTER_CONSUMER_SECRET'] }
  let(:credentials) { [{consumer_key: ck, consumer_secret: cs}] }
  let(:client) { TwitterClient.new(credentials)  }

  describe '#test_access' do
    let(:client) { TwitterClient.new(credentials)  }
    it 'should pass' do
      expect { client.test_access(ck, cs) }.not_to raise_error
    end

    it 'should fail' do
      expect do
        client.test_access('x' * 25, 'y' * 50)
      end.to raise_error(AuthenticationError)
    end
  end

  describe '#followers_ids' do
    let(:client) { TwitterClient.new(credentials)  }
    let(:count)  { Yatc::Settings::MAX_FOLLOWER_IDS }
    it 'should accept user ID' do
      # TwitterDev has many followers!
      expect(client.followers_ids(2244994945).length).to eq count
    end

    it 'should accept user name' do
      expect(client.followers_ids('TwitterDev').length).to eq count
    end

    it 'should retrieve X number of followers' do
      expect(client.followers_ids('TwitterDev', 7493).length).to eq 7493
    end

    it 'should retrieve all followers' do
      followers = client.users_show('__rendon__')['followers_count'].to_i
      expect(client.followers_ids('__rendon__', -1).length).to eq followers
    end
  end

  describe '#friends_ids' do
    let(:client) { TwitterClient.new(credentials)  }
    let(:count)  { Yatc::Settings::MAX_FOLLOWER_IDS }
    it 'should accept user ID' do
      expect(client.friends_ids(15514266).length).to eq count
    end

    it 'should accept user name' do
      expect(client.friends_ids('PRI').length).to eq count
    end

    it 'should retrieve X number of friends' do
      expect(client.friends_ids('PRI', 5001).length).to eq 5001
    end
  end

  describe '#users_show' do
    let(:client) { TwitterClient.new(credentials)  }
    it 'should accept user ID' do
      expect(client.users_show(2244994945)['id_str']).to eq '2244994945'
    end

    it 'should accept user name' do
      expect(client.users_show('TwitterDev')['id_str']).to eq '2244994945'
    end
  end

  describe '#statuses_user_timeline' do
    let(:count) { Yatc::Settings::MAX_TWEETS }
    let(:client) { TwitterClient.new(credentials)  }
    it 'should accept user ID' do
      expect(client.statuses_user_timeline(2244994945).length).to eq count
    end

    it 'should accept user name' do
      expect(client.statuses_user_timeline('TwitterDev').length).to eq count
    end

    it 'should retrieve X tweets' do
      expect(client.statuses_user_timeline('TwitterDev', 211).length).to eq 211
    end
  end
end
