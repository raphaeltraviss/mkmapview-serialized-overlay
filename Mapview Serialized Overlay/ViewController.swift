//
//  ViewController.swift
//  Mapview Serialized Overlay
//
//  Created by Raphael on 1/6/21.
//

import UIKit
import MapKit

class ViewController: UIViewController {
  
  @IBOutlet weak var mapView: MKMapView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    mapView.delegate = self
      
    let pin = MKPointAnnotation()
    let provo = CLLocationCoordinate2D(latitude: 40.2338, longitude: -111.6585)
    pin.coordinate = provo
    
    mapView.addAnnotation(pin)
    
    let region = MKCoordinateRegion(center: provo, latitudinalMeters: 20000, longitudinalMeters: 20000)
    mapView.setRegion(region, animated: true)

    guard let responseData = apiResponse.data(using: .utf8) else { return }
    guard let response = try? JSONDecoder().decode(RawResponse.self, from: responseData) else { return }
    
    let polygonOverlays: [MKPolygon] = response.resultList.map({ polygonData in
      let coords = polygonData.polygonCoordinates
      return MKPolygon(coordinates: coords, count: coords.count)
    })
    let multiPolygonOverlay = MKMultiPolygon(polygonOverlays)
    mapView.addOverlay(multiPolygonOverlay)

    
    let triangleCoords = [
      CLLocationCoordinate2D(latitude: 40.28848530658632, longitude: -111.6632001013793),
      CLLocationCoordinate2D(latitude: 40.211709155849604, longitude: -111.69221087362689),
      CLLocationCoordinate2D(latitude: 40.21813234126653, longitude: -111.6199414350693)
    ]
    let triangle = MKPolygon(coordinates: triangleCoords, count: triangleCoords.count)
    
    mapView.addOverlay(triangle)
  }
}

struct RawResponse: Decodable {
  struct RawPolygon: Decodable {
    var userPolygonId: Int
    var polygonCoordinates: [CLLocationCoordinate2D]
    var userFK: Int

    var createdOn: String
    var colorCode: String
    var profileImg: String?
    var name: String
    var region: String?
    var team: String?
    
    enum CodingKeys: String, CodingKey {
      case userPolygonId, polygonCoordinates, userFK, createdOn, colorCode, profileImg,
           name, region, team
    }
    
    func decodeEmbeddedJSON(_ input: String) -> [CLLocationCoordinate2D] {
      guard let targetData = input.data(using: .utf8) else { return [] }
      guard let pointsListContainer = try? JSONDecoder().decode([[[Double]]].self, from: targetData) else { return [] }
      guard let pointsList = pointsListContainer.first else { return [] }
      
      let points: [CLLocationCoordinate2D] = pointsList.compactMap({ components in
        guard let lat = components.last else { return nil }
        guard let long = components.first else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
      })
      
      return points
    }
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.userPolygonId = try container.decode(Int.self, forKey: .userPolygonId)
      self.userFK = try container.decode(Int.self, forKey: .userFK)
      self.createdOn = try container.decode(String.self, forKey: .createdOn)
      self.colorCode = try container.decode(String.self, forKey: .colorCode)
      self.profileImg = try? container.decode(String.self, forKey: .profileImg)
      self.name = try container.decode(String.self, forKey: .name)
      self.region = try? container.decode(String.self, forKey: .region)
      self.team = try? container.decode(String.self, forKey: .team)
      self.polygonCoordinates = []
      
      // Double-decode polygonCoords, since the server returns embedded JSON
      let rawCoords = try container.decode(String.self, forKey: .polygonCoordinates)
      self.polygonCoordinates = decodeEmbeddedJSON(rawCoords)
    }
  }

  var statusCode: Int
  var errorMessage: String?
  var totalRecords: Int
  var result: String?
  var resultList: [RawPolygon]
}


extension ViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if overlay is MKPolygon {
      let triangleRenderer = MKPolygonRenderer(overlay: overlay)
      triangleRenderer.strokeColor = UIColor.magenta

      return triangleRenderer
    }
    
    let polygonRenderer = MKMultiPolygonRenderer(overlay: overlay)
    polygonRenderer.strokeColor = UIColor.green
    return polygonRenderer
  }
}


let apiResponse = """
{
  "statusCode": 200,
  "errorMessage": null,
  "totalRecords": 0,
  "result": null,
  "resultList": [
    {
        "userPolygonId": 101,
        "polygonCoordinates": "[[[-111.6220367307303,40.18939586004217],[-111.61638743358048,40.159560305968],[-111.58542968839949,40.16118255609291],[-111.58632619005179,40.171122009357134],[-111.60962697619581,40.19133663935918],[-111.6220367307303,40.18939586004217]]]",
        "userFK": 556,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#EDA2FF",
        "profileImg": null,
        "name": "AAAA",
        "region": "Colt Solar ",
        "team": ""
    },
    {
        "userPolygonId": 100,
        "polygonCoordinates": "[[[-111.73566365450034,40.32165114102884],[-111.73384480435942,40.29599167376318],[-111.69383010125784,40.298766140191645],[-111.71080603590678,40.32534899908612],[-111.73051024576726,40.32627343194778],[-111.73566365450034,40.32165114102884]]]",
        "userFK": 792,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#74929B",
        "profileImg": "56418251_2298885133724802_2801269793204731904_n.jpg",
        "name": "Admin",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 105,
        "polygonCoordinates": "[[[-111.98213514324152,40.50777473533006],[-111.95794304217533,40.50774879218591],[-111.95777243497456,40.50058810071383],[-111.9823057504423,40.5009253968156],[-111.98213514324152,40.50777473533006]]]",
        "userFK": 792,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#74929B",
        "profileImg": "56418251_2298885133724802_2801269793204731904_n.jpg",
        "name": "Admin",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 104,
        "polygonCoordinates": "[[[-111.98224276939828,40.50777339032399],[-111.95782594988643,40.50768793782467],[-111.95774165706877,40.50050953919023],[-111.9674915263101,40.501065037936456],[-111.97131280070995,40.50108640318123],[-111.97637036976889,40.502368305399926],[-111.98013544895728,40.50520976798276],[-111.98224276939828,40.50777339032399]]]",
        "userFK": 792,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#74929B",
        "profileImg": "56418251_2298885133724802_2801269793204731904_n.jpg",
        "name": "Admin",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 111,
        "polygonCoordinates": "[[[-111.98467254638577,40.320896477189905],[-111.97540283203023,40.21191635539057],[-111.90948486328051,40.23498448456857],[-111.91257476806553,40.314352150362765],[-111.98467254638577,40.320896477189905]]]",
        "userFK": 438,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#FC51A5",
        "profileImg": null,
        "name": "ADMINISTRATOR",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 12,
        "polygonCoordinates": "[[[-111.9379699230193,40.56253827426289],[-111.93749785423275,40.559978917871234],[-111.93294882774322,40.56102223420177],[-111.93299174308765,40.56221224704046],[-111.9379699230193,40.56253827426289]]]",
        "userFK": 722,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#E935B3",
        "profileImg": null,
        "name": "Ahmed Setter",
        "region": "Synergy",
        "team": "Synergy NV"
    },
    {
        "userPolygonId": 112,
        "polygonCoordinates": "[[[-111.83429718017668,40.380028402511414],[-111.82849748780617,40.35497282903779],[-111.7725358789193,40.335609561747276],[-111.72481401612643,40.364390787004595],[-111.79244859864569,40.38662241152775],[-111.83845384766913,40.3824381955676],[-111.83429718017668,40.380028402511414]]]",
        "userFK": 806,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#BDAF96",
        "profileImg": "d05adbb96b48afa4d16523e014e95c98.jpg",
        "name": "alderadmin adam",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 83,
        "polygonCoordinates": "[[[-112.0543573333773,40.3591659540418],[-112.07418563613162,40.32167317859111],[-112.04863763065978,40.32428962974029],[-112.02957195493424,40.345798827512596],[-112.00440526297699,40.36149040122109],[-111.98419564670768,40.38269727929321],[-112.04063004685513,40.36730116853337],[-112.0543573333773,40.3591659540418]]]",
        "userFK": 804,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#17DD45",
        "profileImg": "ben_beard (2).jpg",
        "name": "Ben Schwen",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 37,
        "polygonCoordinates": "[[[-111.7559962129453,40.38209181941161],[-111.75465575504047,40.367284510159095],[-111.74309430561199,40.37724150751555],[-111.75147216751647,40.393195165902455],[-111.75398552608834,40.38502736486501],[-111.7559962129453,40.38209181941161]]]",
        "userFK": 13,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#1F556C",
        "profileImg": "636724063363659327.jpeg",
        "name": "Brent Tupper",
        "region": "Tephra Florida Region",
        "team": "Tampa Direct"
    },
    {
        "userPolygonId": 71,
        "polygonCoordinates": "[[[-111.8825340270881,40.42818518188366],[-111.82039260863075,40.41407112865443],[-111.83687210081825,40.43184389747921],[-111.8825340270881,40.42818518188366]]]",
        "userFK": 13,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#1F556C",
        "profileImg": "636724063363659327.jpeg",
        "name": "Brent Tupper",
        "region": "Tephra Florida Region",
        "team": "Tampa Direct"
    },
    {
        "userPolygonId": 102,
        "polygonCoordinates": "[[[-111.88545227050834,40.41140480914041],[-111.8847656250004,40.38708936876412],[-111.85798645019587,40.38970435361961],[-111.85317993164115,40.41192762537355],[-111.88545227050834,40.41140480914041]]]",
        "userFK": 28,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#7CEB0C",
        "profileImg": null,
        "name": "Dan Erickson",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 66,
        "polygonCoordinates": "[[[-111.69660421912377,40.32352163958308],[-111.69435038080576,40.31186999512988],[-111.65826809961061,40.31212713461858],[-111.67782671932382,40.324982860668285],[-111.69660421912377,40.32352163958308]]]",
        "userFK": 159,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#AD381E",
        "profileImg": null,
        "name": "Davey Adamson",
        "region": "Synergy",
        "team": "Synergy NV"
    },
    {
        "userPolygonId": 57,
        "polygonCoordinates": "[[[-111.74038767814619,40.28673137894535],[-111.74311280250537,40.28303204179798],[-111.74377799034106,40.28126414547725],[-111.74362778663597,40.280052782417954],[-111.74006581306412,40.2789723592156],[-111.73676133155794,40.28042928947718],[-111.73667550086964,40.27889050826977],[-111.73045277595503,40.27923428157746],[-111.73382163047762,40.286584064080415],[-111.74038767814619,40.28673137894535]]]",
        "userFK": 159,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#AD381E",
        "profileImg": null,
        "name": "Davey Adamson",
        "region": "Synergy",
        "team": "Synergy NV"
    },
    {
        "userPolygonId": 99,
        "polygonCoordinates": "[[[-111.99807481368643,40.386566359608224],[-111.99601487716305,40.33869383689964],[-111.93181352218237,40.33607687246442],[-111.91121415694802,40.38264366149548],[-111.91945390304181,40.41375745019997],[-111.95481614669386,40.38133604469269],[-111.98640184005359,40.38028993297678],[-111.98846177657697,40.38708936876199],[-111.99807481368643,40.386566359608224]]]",
        "userFK": 728,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#491707",
        "profileImg": "E392AB39-C71A-43E4-8071-377FEBC85E62.jpeg",
        "name": "Holden Jasper",
        "region": "Tephra Utah",
        "team": "Tephra Utah Direct"
    },
    {
        "userPolygonId": 78,
        "polygonCoordinates": "[[[-111.69476120033156,40.29663948853067],[-111.68394261467039,40.273332057217374],[-111.67526396903015,40.27369488035967],[-111.67633393904043,40.28222066380525],[-111.65933330443018,40.28321829160339],[-111.65648005106883,40.2978182501129],[-111.69476120033156,40.29663948853067]]]",
        "userFK": 257,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#D1F97B",
        "profileImg": "866295D5-B8A6-42C4-ABC4-292E34645C71.jpeg",
        "name": "Jaleel mardanzai",
        "region": "Colt Solar ",
        "team": "Brandon Palmer Team"
    },
    {
        "userPolygonId": 81,
        "polygonCoordinates": "[[[-111.65525436401425,40.295762803521626],[-111.65768743049006,40.27018683738851],[-111.63262486945467,40.269139001668606],[-111.63502812873212,40.283021507438974],[-111.63331151496233,40.29087826628145],[-111.64017797004084,40.307281227078505],[-111.6515076209198,40.31173190431841],[-111.65525436401425,40.295762803521626]]]",
        "userFK": 4,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#A3DC1D",
        "profileImg": "B2BEF45C-4B1A-486D-82CC-9BCA4D568259.jpeg",
        "name": "Jared Slemboski",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 114,
        "polygonCoordinates": "[[[-111.82262420654423,40.32037295438869],[-111.87721252441533,40.25830676151094],[-111.70726776123153,40.22712123211386],[-111.76322937011834,40.30335625336207],[-111.82262420654423,40.32037295438869]]]",
        "userFK": 4,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#A3DC1D",
        "profileImg": "B2BEF45C-4B1A-486D-82CC-9BCA4D568259.jpeg",
        "name": "Jared Slemboski",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 13,
        "polygonCoordinates": "[[[-111.88279151916426,40.657406575610196],[-111.88158988952544,40.65340201933853],[-111.87517404556186,40.65717868048418],[-111.88214778900054,40.65896926407376],[-111.88279151916426,40.657406575610196]]]",
        "userFK": 4,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#A3DC1D",
        "profileImg": "B2BEF45C-4B1A-486D-82CC-9BCA4D568259.jpeg",
        "name": "Jared Slemboski",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 20,
        "polygonCoordinates": "[[[-111.91941976547236,40.4810342784119],[-111.90866947174085,40.47912467624681],[-111.91302537918084,40.47385258658949],[-111.91418409347551,40.47538692164352],[-111.91542863845821,40.47476666275844],[-111.92004203796397,40.477182375589734],[-111.92004203796397,40.48105059956379],[-111.91941976547236,40.4810342784119]]]",
        "userFK": 3,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#24B66B",
        "profileImg": "Jordan Profile Pic.png",
        "name": "Jordan Adams",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 21,
        "polygonCoordinates": "[[[-111.92001601398256,40.47979126922243],[-111.9158818174241,40.47983158478175],[-111.91166811708548,40.47942842810346],[-111.91169461834542,40.478168547880045],[-111.9122776460651,40.477019516502395],[-111.91335094709471,40.47603173696757],[-111.91532417424959,40.4747816397265],[-111.91896307194584,40.47685221839549],[-111.92010918145647,40.47715735090614],[-111.92001601398256,40.47979126922243]]]",
        "userFK": 3,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#24B66B",
        "profileImg": "Jordan Profile Pic.png",
        "name": "Jordan Adams",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 110,
        "polygonCoordinates": "[[[-112.07702636718787,40.57849862510946],[-112.07702636718787,40.57849862510946],[-112.03668594360362,40.562720849013004],[-112.02758789062511,40.58723347936166],[-112.06226348876969,40.59244777393084],[-112.07702636718787,40.57849862510946]]]",
        "userFK": 3,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#24B66B",
        "profileImg": "Jordan Profile Pic.png",
        "name": "Jordan Adams",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 56,
        "polygonCoordinates": "[[[-111.72401547431961,40.286060275292726],[-111.72377943992647,40.28265554923445],[-111.71693444251959,40.282590072052415],[-111.71808421611672,40.28615848599989],[-111.72401547431961,40.286060275292726]]]",
        "userFK": 1035,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#B86D3E",
        "profileImg": null,
        "name": "Jordan Adams",
        "region": "Tephra Florida Region",
        "team": "Tampa Direct"
    },
    {
        "userPolygonId": 24,
        "polygonCoordinates": "[[[-111.88823818473843,40.476861479413145],[-111.88280811447278,40.484343313036334],[-111.86717119988278,40.48436562668695],[-111.89102262870429,40.47323019337358],[-111.89146269196657,40.47519409130362],[-111.88823818473843,40.476861479413145]]]",
        "userFK": 1035,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#B86D3E",
        "profileImg": null,
        "name": "Jordan Adams",
        "region": "Tephra Florida Region",
        "team": "Tampa Direct"
    },
    {
        "userPolygonId": 23,
        "polygonCoordinates": "[[[-111.91661329756737,40.473682218516416],[-111.91539930710395,40.47479039454146],[-111.91986679200883,40.477006691722806],[-111.91950259486994,40.47525212915349],[-111.91661329756737,40.473682218516416]]]",
        "userFK": 1035,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#B86D3E",
        "profileImg": null,
        "name": "Jordan Adams",
        "region": "Tephra Florida Region",
        "team": "Tampa Direct"
    },
    {
        "userPolygonId": 22,
        "polygonCoordinates": "[[[-111.92021067320469,40.47885661726991],[-111.92333505262188,40.47890090070982],[-111.92325742828865,40.478487587470454],[-111.92273346403857,40.47757238481509],[-111.92261702753827,40.4769081170096],[-111.92290811878826,40.47619955743937],[-111.92331564653855,40.47559432355183],[-111.92343208303834,40.47518098995687],[-111.92327683437195,40.47453146059502],[-111.92261702753827,40.47315857104172],[-111.92036592187104,40.47355715477187],[-111.91976433328776,40.473690015489495],[-111.92021067320469,40.47885661726991]]]",
        "userFK": 1035,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#B86D3E",
        "profileImg": null,
        "name": "Jordan Adams",
        "region": "Tephra Florida Region",
        "team": "Tampa Direct"
    },
    {
        "userPolygonId": 11,
        "polygonCoordinates": "[[[-111.92907949365535,40.566659064626094],[-111.92881363089559,40.55537705947796],[-111.9096335317956,40.55505963541461],[-111.90648115907248,40.56238886177459],[-111.90735470814018,40.567034136994096],[-111.91567241448257,40.56945763086313],[-111.92425598358473,40.56896716894963],[-111.94818363196747,40.5696884352254],[-111.92907949365535,40.566659064626094]]]",
        "userFK": 1035,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#B86D3E",
        "profileImg": null,
        "name": "Jordan Adams",
        "region": "Tephra Florida Region",
        "team": "Tampa Direct"
    },
    {
        "userPolygonId": 27,
        "polygonCoordinates": "[[[-111.94297914326827,40.48210000075014],[-111.9395458544659,40.48212692228864],[-111.93682046026196,40.47192288579984],[-111.94566914274192,40.4697149482468],[-111.94297914326827,40.48210000075014]]]",
        "userFK": 1035,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#B86D3E",
        "profileImg": null,
        "name": "Jordan Adams",
        "region": "Tephra Florida Region",
        "team": "Tampa Direct"
    },
    {
        "userPolygonId": 113,
        "polygonCoordinates": "[[[-111.7167091369592,40.273658393174514],[-111.6967964172327,40.23487965038686],[-111.66074752807232,40.212073667864814],[-111.65628433227175,40.2684193211652],[-111.68443679809181,40.27287255824618],[-111.7167091369592,40.273658393174514]]]",
        "userFK": 760,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#5AD1D0",
        "profileImg": null,
        "name": "Jordan Ryve Admin",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 26,
        "polygonCoordinates": "[[[-111.90973989743188,40.48215039932629],[-111.90702375177646,40.48221300301833],[-111.906077216169,40.48384067852129],[-111.90842297832613,40.484904906548195],[-111.90957528254347,40.483684172975956],[-111.90973989743188,40.48215039932629]]]",
        "userFK": 53,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#85ECB9",
        "profileImg": "Koala.jpg",
        "name": "Production Test - Ignore",
        "region": "Synergy",
        "team": "Synergy NV"
    },
    {
        "userPolygonId": 95,
        "polygonCoordinates": "[[[-111.83750108813827,40.43088078161858],[-111.78086642339707,40.43156505872358],[-111.77996746046479,40.40521536413763],[-111.83030938467913,40.40795347513378],[-111.83750108813827,40.43088078161858]]]",
        "userFK": 1007,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#2B6C3D",
        "profileImg": "ben_beard (3).jpg",
        "name": "Regionmanger Test1",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 10,
        "polygonCoordinates": "[[[-111.9338715076472,40.56501602926039],[-111.93372130394239,40.56253827426309],[-111.92932248115795,40.56234265812],[-111.9293653965021,40.56504863068841],[-111.9338715076472,40.56501602926039]]]",
        "userFK": 1007,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#2B6C3D",
        "profileImg": "ben_beard (3).jpg",
        "name": "Regionmanger Test1",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 94,
        "polygonCoordinates": "[[[-111.73007064169178,40.35155505421869],[-111.7175932902093,40.339698865822754],[-111.69555537070752,40.339698865822754],[-111.69652763186177,40.34550371844375],[-111.70576411282951,40.34575072236882],[-111.70625024340686,40.35278995399352],[-111.73007064169178,40.35155505421869]]]",
        "userFK": 194,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#EEADFB",
        "profileImg": "Scott 2.PNG",
        "name": "Scott Gemmell",
        "region": "",
        "team": ""
    },
    {
        "userPolygonId": 25,
        "polygonCoordinates": "[[[-111.84372137461163,40.476901980296134],[-111.82695135579274,40.48089463899575],[-111.82267136704131,40.47622627610062],[-111.82388268461254,40.47028797707597],[-111.83454227923886,40.470410843755644],[-111.84224087535775,40.47229477135639],[-111.84372137461163,40.476901980296134]]]",
        "userFK": 764,
        "createdOn": "0001-01-01T00:00:00",
        "colorCode": "#CC1E8D",
        "profileImg": null,
        "name": "Test Setter",
        "region": "Test Region",
        "team": "Test Team"
    }
  ]
}
"""
