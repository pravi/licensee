require 'helper'

class TestLicenseeLicense < Minitest::Test
  def setup
    @license = Licensee::License.new 'MIT'
  end

  should 'read the license body' do
    assert @license.body
    msg = "Expected the following to contain MIT:\n#{@license.body}"
    assert @license.text =~ /MIT/, msg
  end

  should 'read the license body if it contains `---`' do
    license = Licensee::License.new 'MIT'
    content = "---\nfoo: bar\n---\nSome license\n---------\nsome text\n"
    license.instance_variable_set(:@raw_content, content)
    assert_equal "Some license\n---------\nsome text\n", license.body
  end

  should 'read the license meta' do
    assert_equal 'MIT License', @license.meta['title']
  end

  should 'know the license path' do
    path = File.expand_path('./vendor/choosealicense.com/_licenses/mit.txt')
    assert_equal path, @license.path
  end

  should 'know the license name' do
    assert_equal 'MIT License', @license.name
  end

  should 'know the license properties' do
    assert_equal 4, @license.meta['permissions'].length
    assert_equal 1, @license.meta['conditions'].length
    assert_equal 1, @license.meta['limitations'].length
  end

  should 'know the license nickname' do
    expected = 'GNU AGPLv3'
    assert_equal expected, Licensee::License.find('agpl-3.0').nickname
  end

  should 'know the license ID' do
    assert_equal 'mit', @license.key
  end

  should 'know the other license' do
    assert_equal 'other', Licensee::License.find_by_key('other').key
  end

  should 'know license equality' do
    assert @license == Licensee::License.new('MIT')
    refute @license == Licensee::License.new('ISC')
    refute @license.nil?
  end

  should 'know if the license is featured' do
    assert @license.featured?
    assert_equal TrueClass, @license.featured?.class
    refute Licensee::License.new('cc0-1.0').featured?
    assert_equal FalseClass, Licensee::License.new('cc0-1.0').featured?.class
  end

  should 'inject default meta without overriding' do
    license = Licensee::License.new('cc0-1.0')

    assert license.meta.key? 'featured'
    assert_equal false, license.meta['featured']

    assert license.meta.key? 'hidden'
    assert_equal false, license.meta['hidden']

    assert license.meta.key? 'variant'
    assert_equal true, license.meta['variant']
  end

  should 'know when the license is hidden' do
    refute @license.hidden?
    assert Licensee::License.new('ofl-1.1').hidden?
    assert Licensee::License.new('no-license').hidden?
  end

  should 'parse the license parts' do
    assert_equal 3, @license.send(:parts).size
  end

  should 'build the license URL' do
    assert_equal 'http://choosealicense.com/licenses/mit/', @license.url
  end

  should 'return all licenses' do
    assert_equal Array, Licensee::License.all.class
    assert Licensee::License.all.size > 3
  end

  should 'strip leading newlines from the license' do
    assert_equal 'T', @license.body[0]
  end

  should 'fail loudly for invalid licenses' do
    assert_raises(Licensee::InvalidLicense) do
      Licensee::License.new('foo').name
    end
  end

  should "support 'other' licenses" do
    license = Licensee::License.new('other')
    assert_equal nil, license.content
    assert_equal 'Other', license.name
    refute license.featured?
  end

  should 'know the license hash' do
    assert_equal 'fb278496ea4663dfcf41ed672eb7e56eb70de798', @license.hash
  end

  describe 'name without version' do
    should 'strip the version from the license name' do
      expected = 'GNU Affero General Public License'
      name = Licensee::License.find('agpl-3.0').name_without_version
      assert_equal expected, name

      expected = 'GNU General Public License'
      name = Licensee::License.find('gpl-2.0').name_without_version
      assert_equal expected, name

      name = Licensee::License.find('gpl-3.0').name_without_version
      assert_equal expected, name
    end

    Licensee.licenses.each do |license|
      should "strip the version number from the #{license.name} license" do
        assert license.name_without_version
      end
    end
  end

  describe 'class methods' do
    should 'know license names' do
      assert_equal Array, Licensee::License.keys.class
      assert_equal 28, Licensee::License.keys.size
    end

    should 'load the licenses' do
      assert_equal Array, Licensee::License.all.class
      assert_equal 15, Licensee::License.all.size
      assert_equal Licensee::License, Licensee::License.all.first.class
    end

    should 'find a license' do
      assert_equal 'mit', Licensee::License.find('mit').key
      assert_equal 'mit', Licensee::License.find('MIT').key
      assert_equal 'mit', Licensee::License['mit'].key
    end

    should 'filter the licenses' do
      assert_equal 28, Licensee::License.all(hidden: true).size
      assert_equal 3,  Licensee::License.all(featured: true).size
      assert_equal 12, Licensee::License.all(featured: false).size

      licenses = Licensee::License.all(featured: false, hidden: true)
      assert_equal 25, licenses.size

      licenses = Licensee::License.all(featured: false, hidden: false)
      assert_equal 12, licenses.size
    end
  end
end
