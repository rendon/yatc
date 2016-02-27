require 'spec_helper'

RSpec.describe TwitterClient do
  let(:ck) { ENV['TWITTER_CONSUMER_KEY'] }
  let(:cs) { ENV['TWITTER_CONSUMER_SECRET'] }
  let(:client) { TwitterClient.new(ck, cs) }
  before(:each) do
    client.request_access_token
  end

  describe '#followers_ids' do
    let(:count) { Yatc::Settings::MAX_FOLLOWER_COUNT }

    it 'should accept user ID' do
      # TwitterDev has many followers!
      expect(client.followers_ids(2_244_994_945).length).to eq count
    end

    it 'should accept user name' do
      expect(client.followers_ids('TwitterDev').length).to eq count
    end

    it 'should retrieve X number of followers' do
      expect(client.followers_ids('TwitterDev', 7493).length).to eq 7493
    end

    it 'should retrieve all followers' do
      count = client.users_show('__rendon__')['followers_count'].to_i
      expect(client.followers_ids('__rendon__', -1).length).to eq count
    end
  end

  describe '#friends_ids' do
    let(:count) { Yatc::Settings::MAX_FRIENDS_COUNT }

    it 'should accept user ID' do
      expect(client.friends_ids(15_514_266).length).to eq count
    end

    it 'should accept user name' do
      expect(client.friends_ids('englishathome').length).to eq count
    end

    it 'should retrieve X number of friends' do
      expect(client.friends_ids('englishathome', 5001).length).to eq 5001
    end
  end

  describe '#users_show' do
    it 'should accept user ID' do
      expect(client.users_show(2_244_994_945)['id_str']).to eq '2244994945'
    end

    it 'should accept user name' do
      expect(client.users_show('TwitterDev')['id_str']).to eq '2244994945'
    end
  end

  describe '#statuses_user_timeline' do
    let(:count) { Yatc::Settings::MAX_TWEETS_COUNT }

    it 'should accept user ID' do
      expect(client.statuses_user_timeline(2_244_994_945).length).to eq count
    end

    it 'should accept user name' do
      expect(client.statuses_user_timeline('TwitterDev').length).to eq count
    end

    it 'should retrieve X tweets' do
      expect(client.statuses_user_timeline('TwitterDev', 211).length).to eq 211
    end
  end
end
